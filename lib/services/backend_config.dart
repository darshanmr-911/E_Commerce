import 'package:flutter/foundation.dart';

const _configuredApiBaseUrl = String.fromEnvironment('FRESHKART_API_BASE_URL');

String get freshKartApiBaseUrl {
  if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
  return defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://127.0.0.1:8000/api/v1';
}

const freshKartBackendEnabled = bool.fromEnvironment(
  'FRESHKART_USE_BACKEND',
  defaultValue: false,
);
