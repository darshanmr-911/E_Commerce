const freshKartApiBaseUrl = String.fromEnvironment(
  'FRESHKART_API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

const freshKartBackendEnabled = bool.fromEnvironment(
  'FRESHKART_USE_BACKEND',
  defaultValue: false,
);
