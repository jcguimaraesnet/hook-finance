// Spec: docs/specs/state/persistence.md
// Spec: docs/specs/api/endpoints.md
//
// Config persistido em shared_preferences. Diferente do PWA, o Flutter precisa
// saber a URL do backend (PWA usa /api/proxy same-origin). Usuário fornece URL
// + token no login.

import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  final String apiBase;
  final String token;

  const ApiConfig({required this.apiBase, required this.token});

  bool get isConfigured => apiBase.isNotEmpty && token.isNotEmpty;
}

const _keyApiBase = 'hook_finance.api_base';
const _keyToken = 'hook_finance.token';

Future<ApiConfig> loadConfig() async {
  final prefs = await SharedPreferences.getInstance();
  return ApiConfig(
    apiBase: prefs.getString(_keyApiBase) ?? '',
    token: prefs.getString(_keyToken) ?? '',
  );
}

Future<void> saveConfig(ApiConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyApiBase, config.apiBase);
  await prefs.setString(_keyToken, config.token);
}

Future<void> clearConfig() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyApiBase);
  await prefs.remove(_keyToken);
}
