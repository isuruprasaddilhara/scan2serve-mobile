/// API origin without trailing slash.
///
/// **Default:** `https://scan2serve.online` (production).
///
/// **Local / staging override** (compile-time; requires full restart after change):
/// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000`
///
/// **Release builds:** pass the same `--dart-define` if you need a non-production API.
String get kApiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (fromEnv.isNotEmpty) {
    return fromEnv.replaceAll(RegExp(r'/$'), '');
  }
  return 'https://scan2serve.online';
}
