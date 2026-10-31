import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:e_commerce/services/customer_api_client.dart';

class _MemoryTokenStore implements CustomerTokenStore {
  final Map<String, String> tokens = {};

  @override
  Future<String?> read(String key) async => tokens[key];

  @override
  Future<void> write(String key, String value) async => tokens[key] = value;

  @override
  Future<void> delete(String key) async => tokens.remove(key);
}

void main() {
  test(
    'sendOtp normalizes Indian phone and returns the server cooldown',
    () async {
      late http.Request request;
      final api = CustomerApiClient(
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'detail':
                  'The verification code was accepted by the SMS provider.',
              'expires_in_seconds': 300,
              'resend_after_seconds': 30,
            }),
            200,
          );
        }),
        tokenStore: _MemoryTokenStore(),
      );

      final cooldown = await api.sendOtp('9876543210');

      expect(request.url.path, endsWith('/auth/send-otp/'));
      expect(jsonDecode(request.body), {'phone': '+919876543210'});
      expect(cooldown, 30);
    },
  );

  test(
    'verifyOtp stores both JWTs only after a valid customer response',
    () async {
      final tokenStore = _MemoryTokenStore();
      late http.Request request;
      final api = CustomerApiClient(
        client: MockClient((incoming) async {
          request = incoming;
          return http.Response(
            jsonEncode({
              'access': 'signed-access-token',
              'refresh': 'signed-refresh-token',
              'role': 'customer',
            }),
            200,
          );
        }),
        tokenStore: tokenStore,
      );

      await api.verifyOtp(phoneNumber: '9876543210', code: '084201');

      expect(request.url.path, endsWith('/auth/verify-otp/'));
      expect(jsonDecode(request.body), {
        'phone': '+919876543210',
        'code': '084201',
      });
      expect(tokenStore.tokens, {
        'freshkart_customer_access': 'signed-access-token',
        'freshkart_customer_refresh': 'signed-refresh-token',
      });
      expect(await api.hasSession, isTrue);
    },
  );

  test('verification errors retain server code and resend cooldown', () async {
    final api = CustomerApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'otp_cooldown',
            'detail': 'Please wait before requesting another code.',
            'retry_after_seconds': 17,
          }),
          429,
        ),
      ),
      tokenStore: _MemoryTokenStore(),
    );

    await expectLater(
      api.sendOtp('9876543210'),
      throwsA(
        isA<CustomerApiException>()
            .having((error) => error.statusCode, 'statusCode', 429)
            .having((error) => error.code, 'code', 'otp_cooldown')
            .having(
              (error) => error.retryAfterSeconds,
              'retryAfterSeconds',
              17,
            ),
      ),
    );
  });

  test('malformed token response does not create a customer session', () async {
    final tokenStore = _MemoryTokenStore();
    final api = CustomerApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'access': 'not-enough', 'role': 'customer'}),
          200,
        ),
      ),
      tokenStore: tokenStore,
    );

    await expectLater(
      api.verifyOtp(phoneNumber: '9876543210', code: '123456'),
      throwsA(isA<CustomerApiException>()),
    );
    expect(tokenStore.tokens, isEmpty);
  });
}
