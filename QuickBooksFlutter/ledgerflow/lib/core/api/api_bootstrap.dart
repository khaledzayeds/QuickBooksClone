import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class ApiBootstrap {
  const ApiBootstrap._();

  static const _profileTypeKey = 'connection.profileType';
  static const _baseUrlKey = 'connection.baseUrl';
  static const _lanHostKey = 'connection.lanHost';
  static const _hostedUrlKey = 'connection.hostedUrl';
  static const _customUrlKey = 'connection.customUrl';

  static Future<String> loadInitialBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final profileType = prefs.getString(_profileTypeKey) ?? 'local';

    final savedBaseUrl = prefs.getString(_baseUrlKey);
    if (profileType == 'local') {
      return AppConstants.localUrl;
    }

    if (profileType == 'lan') {
      return _normalizeLanHost(
        prefs.getString(_lanHostKey) ?? AppConstants.defaultLanHost,
      );
    }

    if (profileType == 'hosted') {
      return _normalizeUrl(
        prefs.getString(_hostedUrlKey) ?? AppConstants.hostedUrl,
      );
    }

    if (profileType == 'custom') {
      return _normalizeUrl(
        prefs.getString(_customUrlKey) ??
            savedBaseUrl ??
            AppConstants.defaultBaseUrl,
      );
    }

    return _normalizeUrl(savedBaseUrl ?? AppConstants.defaultBaseUrl);
  }

  static String _normalizeLanHost(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return AppConstants.localUrl;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _stripTrailingSlash(trimmed);
    }
    return _stripTrailingSlash('http://$trimmed');
  }

  static String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return AppConstants.localUrl;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _stripTrailingSlash(trimmed);
    }
    return _stripTrailingSlash('http://$trimmed');
  }

  static String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
