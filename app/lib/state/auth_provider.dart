// Spec: docs/specs/state/persistence.md

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/biometric_service.dart';
import '../api/client.dart';
import '../api/config.dart';
import '../api/endpoints.dart';

class AuthState {
  final ApiConfig config;
  final bool ready;
  // Quando true, há token persistido com biometricEnabled mas usuário ainda
  // não autenticou via biometria neste boot. Router deixa em /login até passar.
  final bool awaitingBiometric;

  const AuthState({
    required this.config,
    required this.ready,
    this.awaitingBiometric = false,
  });

  bool get isAuthed => ready && config.isConfigured && !awaitingBiometric;
}

class AuthNotifier extends Notifier<AuthState> {
  final BiometricService _bio = BiometricService();

  @override
  AuthState build() => const AuthState(
        config: ApiConfig(token: ''),
        ready: false,
      );

  /// Carrega config persistido. Se biometria estava ativa, marca
  /// awaitingBiometric=true até o usuário confirmar via prompt.
  Future<void> hydrate() async {
    final config = await loadConfig();
    final needsBio = config.token.isNotEmpty && config.biometricEnabled;
    state = AuthState(
      config: config,
      ready: true,
      awaitingBiometric: needsBio,
    );
    if (needsBio) {
      // Tenta auto-prompt logo após hydrate para abrir direto na Consulta.
      final ok = await _bio.authenticate();
      if (ok) {
        state = state.copyWith(awaitingBiometric: false);
      } else {
        // Cancelado/falha: limpa o token (volta para LoginScreen).
        await clearConfig();
        state = AuthState(
          config: const ApiConfig(token: ''),
          ready: true,
        );
      }
    }
  }

  Future<bool> isBiometricAvailable() => _bio.isAvailable();

  Future<ValidationResult> signIn(String token, {bool useBiometric = false}) async {
    final candidate = ApiConfig(
      token: token.trim(),
      biometricEnabled: useBiometric,
    );
    final result = await validateConfig(candidate);
    if (!result.ok) return result;
    await saveConfig(candidate);
    state = AuthState(config: candidate, ready: true);
    return result;
  }

  Future<void> signOut() async {
    await clearConfig();
    state = const AuthState(
      config: ApiConfig(token: ''),
      ready: true,
    );
  }
}

extension on AuthState {
  AuthState copyWith({
    ApiConfig? config,
    bool? ready,
    bool? awaitingBiometric,
  }) =>
      AuthState(
        config: config ?? this.config,
        ready: ready ?? this.ready,
        awaitingBiometric: awaitingBiometric ?? this.awaitingBiometric,
      );
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(authProvider).config;
  return ApiClient(config);
});

final apiProvider = Provider<ApiEndpoints>((ref) {
  return ApiEndpoints(ref.watch(apiClientProvider));
});
