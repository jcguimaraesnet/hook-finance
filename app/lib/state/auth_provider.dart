// Spec: docs/specs/state/persistence.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/client.dart';
import '../api/config.dart';
import '../api/endpoints.dart';

class AuthState {
  final ApiConfig config;
  final bool ready;

  const AuthState({required this.config, required this.ready});

  bool get isAuthed => ready && config.isConfigured;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(
        config: ApiConfig(token: ''),
        ready: false,
      );

  Future<void> hydrate() async {
    final config = await loadConfig();
    state = AuthState(config: config, ready: true);
  }

  Future<bool> signIn(String token) async {
    final candidate = ApiConfig(token: token.trim());
    final ok = await validateConfig(candidate);
    if (!ok) return false;
    await saveConfig(candidate);
    state = AuthState(config: candidate, ready: true);
    return true;
  }

  Future<void> signOut() async {
    await clearConfig();
    state = const AuthState(
      config: ApiConfig(token: ''),
      ready: true,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(authProvider).config;
  return ApiClient(config);
});

final apiProvider = Provider<ApiEndpoints>((ref) {
  return ApiEndpoints(ref.watch(apiClientProvider));
});
