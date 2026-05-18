// app_constants.dart
// core/constants/app_constants.dart

class AppConstants {
  // Single source of truth for the local desktop API endpoint.
  // QuickBooksClone.Api/Properties/launchSettings.json listens on this port.
  static const localUrl = 'http://localhost:5014';
  static const defaultBaseUrl = localUrl;

  // Defaults used by the connection settings screen.
  static const defaultLanHost = '192.168.1.100:5014';
  static const lanUrl = 'http://192.168.1.100:5014';
  static const hostedUrl = 'https://your-server.com';
}
