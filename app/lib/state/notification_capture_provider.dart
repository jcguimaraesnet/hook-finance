// Spec: docs/specs/features/captura-notificacoes.md
//
// Estado + orquestrador da feature "Captura de notificações". Lê/escreve
// SharedPreferences, escuta o stream de notificações do plugin
// notification_listener_service (Android-only) e POSTa no webhook do
// Apps Script via ApiClient (mesmo padrão title+text que Tasker hoje).

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

class NotificationCaptureState {
  final bool enabled;
  final String packageName;
  final String titleRegex;
  final DateTime? lastCaptureAt;
  final String? lastCaptureTitle;
  final String? lastError;
  final bool hydrated;

  const NotificationCaptureState({
    this.enabled = false,
    this.packageName = '',
    this.titleRegex = '',
    this.lastCaptureAt,
    this.lastCaptureTitle,
    this.lastError,
    this.hydrated = false,
  });

  NotificationCaptureState copyWith({
    bool? enabled,
    String? packageName,
    String? titleRegex,
    DateTime? lastCaptureAt,
    String? lastCaptureTitle,
    Object? lastError = _sentinel,
    bool? hydrated,
  }) {
    return NotificationCaptureState(
      enabled: enabled ?? this.enabled,
      packageName: packageName ?? this.packageName,
      titleRegex: titleRegex ?? this.titleRegex,
      lastCaptureAt: lastCaptureAt ?? this.lastCaptureAt,
      lastCaptureTitle: lastCaptureTitle ?? this.lastCaptureTitle,
      lastError: identical(lastError, _sentinel)
          ? this.lastError
          : lastError as String?,
      hydrated: hydrated ?? this.hydrated,
    );
  }
}

const _sentinel = Object();

const _kEnabled = 'nc_enabled';
const _kPackage = 'nc_package';
const _kTitleRegex = 'nc_title_regex';
const _kLastCaptureMs = 'nc_last_capture_ms';
const _kLastCaptureTitle = 'nc_last_capture_title';

class NotificationCaptureNotifier extends Notifier<NotificationCaptureState> {
  @override
  NotificationCaptureState build() => const NotificationCaptureState();

  Future<void> hydrate() async {
    final p = await SharedPreferences.getInstance();
    final lastMs = p.getInt(_kLastCaptureMs);
    state = state.copyWith(
      enabled: p.getBool(_kEnabled) ?? false,
      packageName: p.getString(_kPackage) ?? '',
      titleRegex: p.getString(_kTitleRegex) ?? '',
      lastCaptureAt: lastMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMs),
      lastCaptureTitle: p.getString(_kLastCaptureTitle),
      hydrated: true,
    );
  }

  Future<void> setEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, v);
    state = state.copyWith(enabled: v, lastError: null);
  }

  Future<void> setPackage(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPackage, v);
    state = state.copyWith(packageName: v);
  }

  Future<void> setTitleRegex(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTitleRegex, v);
    state = state.copyWith(titleRegex: v);
  }

  Future<void> markCapture({required String title}) async {
    final now = DateTime.now();
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLastCaptureMs, now.millisecondsSinceEpoch);
    await p.setString(_kLastCaptureTitle, title);
    state = state.copyWith(
      lastCaptureAt: now,
      lastCaptureTitle: title,
      lastError: null,
    );
  }

  void setError(String? error) {
    state = state.copyWith(lastError: error);
  }
}

final notificationCaptureProvider =
    NotifierProvider<NotificationCaptureNotifier, NotificationCaptureState>(
  NotificationCaptureNotifier.new,
);

/// Orquestrador: assina o stream do plugin sempre que (enabled,
/// packageName, titleRegex) mudar. Filtra eventos e POSTa no webhook
/// via ApiClient. Só ativa no Android.
///
/// Para garantir que rode mesmo sem ninguém observar, é "force-instantiated"
/// no app.dart após o auth hydrate.
final notificationCaptureControllerProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;

  StreamSubscription<ServiceNotificationEvent>? sub;

  Future<void> restart() async {
    await sub?.cancel();
    sub = null;
    final config = ref.read(notificationCaptureProvider);
    if (!config.enabled) return;
    if (config.packageName.trim().isEmpty) return;
    final granted = await NotificationListenerService.isPermissionGranted();
    if (!granted) return;
    sub = NotificationListenerService.notificationsStream.listen((event) async {
      await _handleEvent(ref, event);
    });
  }

  ref.listen<NotificationCaptureState>(
    notificationCaptureProvider,
    (prev, next) {
      if (prev?.enabled != next.enabled ||
          prev?.packageName != next.packageName ||
          prev?.titleRegex != next.titleRegex) {
        restart();
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(() async {
    await sub?.cancel();
  });
});

Future<void> _handleEvent(Ref ref, ServiceNotificationEvent event) async {
  final notifier = ref.read(notificationCaptureProvider.notifier);
  final config = ref.read(notificationCaptureProvider);

  if (event.hasRemoved == true) return;
  if (event.packageName != config.packageName) return;

  final title = event.title ?? '';
  final content = event.content ?? '';
  if (config.titleRegex.isNotEmpty) {
    try {
      if (!RegExp(config.titleRegex).hasMatch(title)) return;
    } catch (_) {
      // Regex inválida: trata como "sem filtro" e segue.
    }
  }
  if (title.isEmpty && content.isEmpty) return;

  final client = ref.read(apiClientProvider);
  try {
    // Backend dispatcha pelo webhook quando body tem title+text (action é
    // ignorada nesse caminho — ver Dashboard.gs doPost). Reusa ApiClient
    // pra herdar o token persistido no auth.
    final r = await client.post('webhookFromApp', {
      'title': title,
      'text': content,
    });
    if (r['ok'] == true) {
      await notifier.markCapture(title: title.isEmpty ? '(sem título)' : title);
    } else {
      notifier.setError('Backend: ${r['error'] ?? 'erro'}');
    }
  } catch (err) {
    notifier.setError('$err');
  }
}
