import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../features/categories/data/categories_sample_data.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'backend_config.dart';

class CustomerApiException implements Exception {
  const CustomerApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.retryAfterSeconds,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}

abstract interface class CustomerTokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureCustomerTokenStore implements CustomerTokenStore {
  SecureCustomerTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class CustomerApiClient {
  CustomerApiClient({
    http.Client? client,
    FlutterSecureStorage? storage,
    CustomerTokenStore? tokenStore,
  }) : _client = client ?? http.Client(),
       _tokenStore = tokenStore ?? SecureCustomerTokenStore(storage);

  static const _accessKey = 'freshkart_customer_access';
  static const _refreshKey = 'freshkart_customer_refresh';
  final http.Client _client;
  final CustomerTokenStore _tokenStore;

  Future<bool> get hasSession async =>
      (await _tokenStore.read(_accessKey)) != null;

  Future<int> sendOtp(String phoneNumber) async {
    final response = await _postAuth('/auth/send-otp/', {
      'phone': _normalizePhone(phoneNumber),
    });
    final body = _decodeObject(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _authException(response, body);
    }
    final resendAfter = body['resend_after_seconds'];
    if (resendAfter is! int || resendAfter < 1) {
      throw const CustomerApiException(
        'The API returned an invalid OTP response.',
      );
    }
    return resendAfter;
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final response = await _postAuth('/auth/verify-otp/', {
      'phone': _normalizePhone(phoneNumber),
      'code': code,
    });
    final body = _decodeObject(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _authException(response, body);
    }
    if (body['role'] != 'customer' ||
        body['access'] is! String ||
        body['refresh'] is! String) {
      throw const CustomerApiException(
        'The API returned an invalid customer session.',
      );
    }
    try {
      await _tokenStore.write(_refreshKey, body['refresh'] as String);
      await _tokenStore.write(_accessKey, body['access'] as String);
    } on PlatformException {
      throw const CustomerApiException(
        'Your device could not securely store the sign-in session.',
      );
    }
  }

  Future<void> login(String identifier, String password) async {
    final response = await _postAuth('/auth/customer/login/', {
      'identifier': identifier,
      'password': password,
    });
    final body = _decodeObject(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _authException(response, body);
    }
    if (body['role'] != 'customer' ||
        body['access'] is! String ||
        body['refresh'] is! String) {
      throw const CustomerApiException(
        'The API returned an invalid customer session.',
      );
    }
    try {
      await _tokenStore.write(_accessKey, body['access'] as String);
      await _tokenStore.write(_refreshKey, body['refresh'] as String);
    } on PlatformException {
      throw const CustomerApiException(
        'Your device could not securely store the sign-in session.',
      );
    }
  }

  Future<List<GroceryProduct>> fetchProducts({String? categoryName}) async {
    final search = categoryName == null
        ? ''
        : '?search=${Uri.encodeQueryComponent(categoryName)}';
    final response = await _client.get(_uri('/products/$search'));
    final body = _decodeObject(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CustomerApiException(
        _errorMessage(body),
        statusCode: response.statusCode,
      );
    }
    final rows = body['results'];
    if (rows is! List) {
      throw const CustomerApiException(
        'The API returned an invalid product list.',
      );
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .where(
          (product) =>
              categoryName == null ||
              '${product['category_name']}'.toLowerCase() ==
                  categoryName.toLowerCase(),
        )
        .map((row) => _toProduct(row))
        .toList();
  }

  Future<Map<String, dynamic>> createOrder({
    required Map<String, Object?> address,
    required List<Map<String, Object?>> items,
    required String couponCode,
  }) async {
    final body = <String, Object?>{
      'delivery_address_snapshot': address,
      'payment_method': 'upi',
      'items': items,
      if (couponCode.isNotEmpty) 'coupon_code': couponCode,
    };
    var response = await _authorizedPost('/orders/', body);
    if (response.statusCode == 401) {
      await _refreshSession();
      response = await _authorizedPost('/orders/', body);
    }
    final result = _decodeObject(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CustomerApiException(
        _errorMessage(result),
        statusCode: response.statusCode,
      );
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final response = await _authorizedRequest('GET', '/orders/');
    final body = _decodeObject(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CustomerApiException(
        _errorMessage(body),
        statusCode: response.statusCode,
      );
    }
    final rows = body['results'];
    if (rows is! List) {
      throw const CustomerApiException(
        'The API returned an invalid order list.',
      );
    }
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final response = await _authorizedRequest(
      'PATCH',
      '/orders/$orderId/cancel/',
      body: jsonEncode(<String, Object?>{}),
    );
    final result = _decodeObject(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CustomerApiException(
        _errorMessage(result),
        statusCode: response.statusCode,
      );
    }
    return result;
  }

  Future<String?> logout() async {
    final refresh = await _tokenStore.read(_refreshKey);
    await _tokenStore.delete(_accessKey);
    await _tokenStore.delete(_refreshKey);
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

  Future<http.Response> _authorizedPost(
    String path,
    Map<String, Object?> body,
  ) async {
    final token = await _tokenStore.read(_accessKey);
    if (token == null) {
      throw const CustomerApiException(
        'Sign in to your customer account to order.',
      );
    }
    return _client.post(
      _uri(path),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _authorizedRequest(
    String method,
    String path, {
    Object? body,
  }) async {
    Future<http.Response> send() async {
      final token = await _tokenStore.read(_accessKey);
      if (token == null) {
        throw const CustomerApiException('Sign in to your customer account.');
      }
      return _client
          .send(
            http.Request(method, _uri(path))
              ..headers.addAll({
                'content-type': 'application/json',
                'authorization': 'Bearer $token',
              })
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
    final refresh = await _tokenStore.read(_refreshKey);
    if (refresh == null) {
      await logout();
      throw const CustomerApiException(
        'Your customer session expired. Sign in again.',
      );
    }
    final response = await _client.post(
      _uri('/auth/token/refresh/'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    final body = _decodeObject(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['access'] is! String) {
      await logout();
      throw const CustomerApiException(
        'Your customer session expired. Sign in again.',
      );
    }
    await _tokenStore.write(_accessKey, body['access'] as String);
    if (body['refresh'] case final String rotatedRefresh) {
      await _tokenStore.write(_refreshKey, rotatedRefresh);
    }
  }

  GroceryProduct _toProduct(Map<String, dynamic> data) {
    final categoryName = '${data['category_name'] ?? ''}';
    final category = categoryCatalog.cast<GroceryCategory?>().firstWhere(
      (item) => item?.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => null,
    );
    final sample = categorySampleProducts
        .where(
          (product) =>
              product.category.toLowerCase() == categoryName.toLowerCase(),
        )
        .firstOrNull;
    final sellingPaise = _paise(data['selling_price']);
    final originalPaise = _paise(data['original_price']);
    final discount = originalPaise <= 0
        ? 0
        : ((originalPaise - sellingPaise) * 100 ~/ originalPaise).clamp(0, 100);
    return GroceryProduct(
      id: '${data['id']}',
      categoryId: category?.id ?? '',
      name: '${data['name'] ?? ''}',
      price: originalPaise ~/ 100,
      unit: '${data['unit'] ?? 'piece'}',
      category: categoryName,
      illustration: sample?.illustration ?? '🛒',
      backgroundColor: category?.backgroundColor ?? const Color(0xFFE9F4E6),
      accentColor: category?.accentColor ?? const Color(0xFF3D824A),
      description: '${data['description'] ?? ''}',
      imageUrl: '${data['image'] ?? ''}',
      stockCount: (data['stock_quantity'] as int? ?? 0).clamp(
        0,
        data['maximum_order_quantity'] as int? ?? 50,
      ),
      discountPercent: discount,
      isAvailable: data['is_available'] == true,
      originalPricePaiseOverride: originalPaise,
      discountedPricePaiseOverride: sellingPaise,
      minimumOrderQuantity: data['minimum_order_quantity'] as int? ?? 1,
    );
  }

  int _paise(Object? value) {
    final parsed = double.tryParse('$value');
    if (parsed == null || !parsed.isFinite) {
      throw const CustomerApiException(
        'The API returned an invalid product price.',
      );
    }
    return (parsed * 100).round();
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CustomerApiException('The API returned an invalid response.');
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

  Future<http.Response> _postAuth(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      return await _client.post(
        _uri(path),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(body),
      );
    } on http.ClientException {
      throw const CustomerApiException(
        'Could not reach FreshKart. Check your connection and try again.',
      );
    }
  }

  CustomerApiException _authException(
    http.Response response,
    Map<String, dynamic> body,
  ) {
    final retryAfter = body['retry_after_seconds'];
    return CustomerApiException(
      _errorMessage(body),
      statusCode: response.statusCode,
      code: body['code'] is String ? body['code'] as String : null,
      retryAfterSeconds: retryAfter is int
          ? retryAfter
          : int.tryParse(response.headers['retry-after'] ?? ''),
    );
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final nationalNumber = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;
    return '+91$nationalNumber';
  }

  Uri _uri(String path) {
    final base = freshKartApiBaseUrl.endsWith('/')
        ? freshKartApiBaseUrl.substring(0, freshKartApiBaseUrl.length - 1)
        : freshKartApiBaseUrl;
    return Uri.parse('$base$path');
  }
}
