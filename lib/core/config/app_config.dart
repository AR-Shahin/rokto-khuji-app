/// App-wide settings.
///
/// Change the API address at build time, without touching the code:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://roktokhuji.com/api/v1',
  );

  static const String website = 'https://roktokhuji.com';
  static const String appVersion = '1.0.0';

  /// Sent to the API on login so the user can see which phone a session belongs to.
  static const String deviceName = 'Rokto Khuji app';

  static const Duration requestTimeout = Duration(seconds: 25);
  static const int pageSize = 15;
}
