// Spec: docs/specs/features/captura-notificacoes.md (Histórico de capturas)
//
// Provider que mantém em memória + persiste em
// `<app_documents_dir>/capture_history.json` as últimas 50 capturas
// de notificação. Web é no-op (path_provider não suporta).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'capture_log_entry.dart';

const int _maxEntries = 50;
const String _fileName = 'capture_history.json';

class CaptureHistoryNotifier
    extends AsyncNotifier<List<CaptureLogEntry>> {
  File? _cachedFile;

  Future<File?> _file() async {
    if (kIsWeb) return null;
    if (_cachedFile != null) return _cachedFile;
    final dir = await getApplicationDocumentsDirectory();
    _cachedFile = File('${dir.path}/$_fileName');
    return _cachedFile;
  }

  @override
  Future<List<CaptureLogEntry>> build() async {
    final f = await _file();
    if (f == null || !await f.exists()) return const [];
    try {
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CaptureLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> append(CaptureLogEntry entry) async {
    final current = state.valueOrNull ?? const <CaptureLogEntry>[];
    final next = <CaptureLogEntry>[entry, ...current];
    final trimmed = next.length > _maxEntries
        ? next.sublist(0, _maxEntries)
        : next;
    state = AsyncValue.data(trimmed);
    final f = await _file();
    if (f == null) return;
    try {
      await f.writeAsString(
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {
      // Best-effort persist: estado em memória já foi atualizado.
    }
  }

  Future<void> clear() async {
    state = const AsyncValue.data([]);
    final f = await _file();
    if (f == null) return;
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {
      // ignora
    }
  }
}

final captureHistoryProvider = AsyncNotifierProvider<
    CaptureHistoryNotifier, List<CaptureLogEntry>>(
  CaptureHistoryNotifier.new,
);
