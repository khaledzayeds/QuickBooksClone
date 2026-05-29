import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _authTokenKey = 'auth.token';
  static const _authExpiresAtKey = 'auth.expiresAt';

  Future<void> saveAuthSession({
    required String companyScope,
    required String token,
    required DateTime expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(_authTokenKey, companyScope), token);
    await prefs.setString(
      _scopedKey(_authExpiresAtKey, companyScope),
      expiresAt.toIso8601String(),
    );
  }

  Future<String?> readAuthToken({required String companyScope}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_scopedKey(_authTokenKey, companyScope));
    final expiresAtValue = prefs.getString(
      _scopedKey(_authExpiresAtKey, companyScope),
    );
    final expiresAt = DateTime.tryParse(expiresAtValue ?? '');

    if (token == null ||
        token.isEmpty ||
        expiresAt == null ||
        DateTime.now().isAfter(expiresAt)) {
      await clearAuthSession(companyScope: companyScope);
      return null;
    }

    return token;
  }

  Future<void> clearAuthSession({required String companyScope}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedKey(_authTokenKey, companyScope));
    await prefs.remove(_scopedKey(_authExpiresAtKey, companyScope));
  }

  Future<void> clearAllAuthSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) =>
          key == _authTokenKey ||
          key == _authExpiresAtKey ||
          key.startsWith('$_authTokenKey.') ||
          key.startsWith('$_authExpiresAtKey.'),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  String _scopedKey(String key, String companyScope) {
    final normalizedScope = companyScope.trim();
    return normalizedScope.isEmpty ? key : '$key.$normalizedScope';
  }
}
