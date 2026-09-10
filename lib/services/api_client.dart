import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  String? get token => _token;

  void setToken(String? token) => _token = token;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return _request(_client.get(_uri(path, query), headers: _headers()));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request(
      _client.post(
        _uri(path),
        headers: _headers(jsonBody: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _request(
      _client.patch(
        _uri(path),
        headers: _headers(jsonBody: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _request(_client.delete(_uri(path), headers: _headers()));
  }

  Future<Map<String, dynamic>> _request(Future<http.Response> request) async {
    try {
      return _decode(await request.timeout(const Duration(seconds: 20)));
    } on TimeoutException {
      throw ApiException(0, 'The request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException(
        0,
        'Unable to connect. Check your connection and try again.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> json = {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        } else {
          json = {'data': decoded};
        }
      } on FormatException {
        throw ApiException(
          res.statusCode,
          'Unexpected server response. Please try later.',
        );
      }
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        res.statusCode,
        (json['error'] as String?) ?? 'Request failed (${res.statusCode})',
      );
    }
    return json;
  }

  void close() => _client.close();

  Future<bool> healthCheck() async {
    try {
      final res = await _client
          .get(_uri('/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
