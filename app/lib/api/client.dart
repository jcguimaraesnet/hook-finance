// Spec: docs/specs/api/endpoints.md
// Spec: docs/specs/api/proxy.md

import 'dart:convert';
import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  final Dio _dio;
  final ApiConfig _config;

  ApiClient(this._config) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  Future<Map<String, dynamic>> get(
    String action, {
    Map<String, dynamic> params = const {},
  }) async {
    final query = <String, dynamic>{
      'action': action,
      'token': _config.token,
      ...params,
    }..removeWhere((_, v) => v == null);
    final r = await _dio.getUri(
      Uri.parse(_config.apiBase).replace(
        queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
      ),
    );
    return _decode(r.data);
  }

  Future<Map<String, dynamic>> post(
    String action,
    Map<String, dynamic> body,
  ) async {
    // text/plain evita preflight CORS no Apps Script direto.
    final payload = {
      'action': action,
      'token': _config.token,
      ...body,
    };
    final r = await _dio.postUri(
      Uri.parse(_config.apiBase),
      data: jsonEncode(payload),
      options: Options(
        headers: {'Content-Type': 'text/plain'},
        responseType: ResponseType.plain,
      ),
    );
    return _decode(r.data);
  }

  Map<String, dynamic> _decode(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw FormatException('Unexpected response payload: $raw');
  }
}

/// Valida URL+token tentando lastEntries(n=1).
Future<bool> validateConfig(ApiConfig config) async {
  if (!config.isConfigured) return false;
  try {
    final client = ApiClient(config);
    final r = await client.get('lastEntries', params: {'n': 1});
    return r['ok'] == true;
  } catch (_) {
    return false;
  }
}
