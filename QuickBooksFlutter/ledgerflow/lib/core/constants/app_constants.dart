// app_constants.dart
// core/constants/app_constants.dart

class AppConstants {
  // الـ base URL من الـ FRONTEND_INTEGRATION_GUIDE
  static const defaultBaseUrl = 'http://localhost:5014';

  // يتغير حسب الـ connection profile (Local / LAN / Hosted)
  static const localUrl = 'http://localhost:5014';
  static const lanUrl = 'http://192.168.1.x:5014'; // يتغير
  static const hostedUrl = 'https://your-server.com';
}
