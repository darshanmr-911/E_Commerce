import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../services/backend_config.dart';

class OwnerApiException implements Exception {
  const OwnerApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class OwnerApiClient {
  OwnerApiClient({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'freshkart_owner_access';
  static const _refreshKey = 'freshkart_owner_refresh';
  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<bool> get hasSession async =>
      (await _storage.read(key: _accessKey)) != null;

  Future<void> login(String identifier, String password) async {
    final response = await _client.post(
      _uri('/owner/login/'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerApiException(
        _errorMessage(body),
        statusCode: response.statusCode,
      );
    }
    if (body['role'] != 'owner' ||
        body['access'] is! String ||
        body['refresh'] is! String) {
      throw const OwnerApiException(
        'The API returned an invalid owner session.',
      );
    }
    await _storage.write(key: _accessKey, value: body['access'] as String);
    await _storage.write(key: _refreshKey, value: body['refresh'] as String);
  }

  Future<String?> logout() async {
    final refresh = await _storage.read(key: _refreshKey);
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    if (refresh == null) return null;
    try {
      final response = await _client.post(
        _uri('/auth/token/blacklist/'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Your device was signed out, but the server could not revoke the refresh token.';
      }
    } on http.ClientException {
      return 'Your device was signed out, but the server could not be reached to revoke the refresh token.';
    }
    return null;
  }

  Future<Map<String, dynamic>> getObject(String path) async {
    final response = await _authorizedRequest('GET', path);
    return _requireObject(response);
  }

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final response = await _authorizedRequest('GET', path);
    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerApiException(
        _errorMessage(body),
        statusCode: response.statusCode,
      );
    }
    final Object? rows = body['results'] ?? body['data'] ?? body;
    if (rows is! List) {
      throw const OwnerApiException('The API response did not contain a list.');
    }
    return rows.map((row) {
      if (row is! Map<String, dynamic>) {
        throw const OwnerApiException('The API returned an invalid list item.');
      }
      return row;
    }).toList();
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object?> data,
  ) async {
    return _requireObject(
      await _authorizedRequest(
        'POST',
        path,
        body: jsonEncode(data),
        headers: const {'content-type': 'application/json'},
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, Object?> data,
  ) async {
    return _requireObject(
      await _authorizedRequest(
        'PATCH',
        path,
        body: jsonEncode(data),
        headers: const {'content-type': 'application/json'},
      ),
    );
  }

  Future<void> delete(String path) async {
    final response = await _authorizedRequest('DELETE', path);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerApiException(
        _errorMessage(_decodeResponse(response)),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> upload(
    String path,
    Map<String, String> fields, {
    required String method,
    String? imageName,
    List<int>? imageBytes,
    String imageField = 'image',
  }) async {
    Future<http.Response> send() async {
      final request = http.MultipartRequest(method, _uri(path));
      final token = await _storage.read(key: _accessKey);
      if (token != null) request.headers['authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      if (imageBytes != null && imageName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            imageField,
            imageBytes,
            filename: imageName,
          ),
        );
      }
      return http.Response.fromStream(await _client.send(request));
    }

    var response = await send();
    if (response.statusCode == 401) {
      await _refreshSession();
      response = await send();
    }
    return _requireObject(response);
  }

  Future<http.Response> _authorizedRequest(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    Future<http.Response> send() async {
      final token = await _storage.read(key: _accessKey);
      if (token == null) {
        throw const OwnerApiException(
          'Your owner session has expired. Sign in again.',
        );
      }
      return _client
          .send(
            http.Request(method, _uri(path))
              ..headers.addAll({'authorization': 'Bearer $token', ...?headers})
              ..body = body?.toString() ?? '',
          )
          .then(http.Response.fromStream);
    }

    var response = await send();
    if (response.statusCode == 401) {
      await _refreshSession();
      response = await send();
    }
    return response;
  }

  Future<void> _refreshSession() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) {
      await logout();
      throw const OwnerApiException(
        'Your owner session expired. Sign in again.',
      );
    }
    final response = await _client.post(
      _uri('/auth/token/refresh/'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    final body = _decodeResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['access'] is! String) {
      await logout();
      throw const OwnerApiException(
        'Your owner session expired. Sign in again.',
      );
    }
    await _storage.write(key: _accessKey, value: body['access'] as String);
    if (body['refresh'] case final String rotatedRefresh) {
      await _storage.write(key: _refreshKey, value: rotatedRefresh);
    }
  }

  Map<String, dynamic> _requireObject(http.Response response) {
    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OwnerApiException(
        _errorMessage(body),
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OwnerApiException('The API returned an invalid response.');
    }
    return decoded;
  }

  String _errorMessage(Map<String, dynamic> body) {
    final detail = body['detail'];
    if (detail is String) return detail;
    if (detail != null) return detail.toString();
    return body.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }

  Uri _uri(String path) {
    final base = freshKartApiBaseUrl.endsWith('/')
        ? freshKartApiBaseUrl.substring(0, freshKartApiBaseUrl.length - 1)
        : freshKartApiBaseUrl;
    return Uri.parse('$base$path');
  }
}
