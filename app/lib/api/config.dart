// Spec: docs/specs/state/persistence.md
// Spec: docs/specs/api/endpoints.md
//
// URL do backend é compilada no app via String.fromEnvironment.
// Default aponta para o /api/proxy do Azure SWA. Override em build time:
//   flutter build apk --dart-define=API_BASE=https://outra/api/proxy

import 'package:shared_preferences/shared_preferences.dart';

const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue:
      'https://polite-mushroom-0d3d07a0f.7.azurestaticapps.net/api/proxy',
);

class ApiConfig {
  final String token;

  const ApiConfig({required this.token});

  String get apiBase => kApiBase;
  bool get isConfigured => token.isNotEmpty;
}

const _keyToken = 'hook_finance.token';

Future<ApiConfig> loadConfig() async {
  final prefs = await SharedPreferences.getInstance();
  return ApiConfig(token: prefs.getString(_keyToken) ?? '');
}

Future<void> saveConfig(ApiConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyToken, config.token);
}

Future<void> clearConfig() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyToken);
  // Limpa chave legada (Onda 4 antes do hardcode).
  await prefs.remove('hook_finance.api_base');
}
