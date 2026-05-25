import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _authTokenKey = 'auth.token';
  static const _authExpiresAtKey = 'auth.expiresAt';

  Future<void> saveAuthSession({
    required String token,
    required DateTime expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    await prefs.setString(_authExpiresAtKey, expiresAt.toIso8601String());
  }

  Future<String?> readAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    final expiresAtValue = prefs.getString(_authExpiresAtKey);
    final expiresAt = DateTime.tryParse(expiresAtValue ?? '');

    if (token == null ||
        token.isEmpty ||
        expiresAt == null ||
        DateTime.now().isAfter(expiresAt)) {
      await clearAuthSession();
      return null;
    }

    return token;
  }

  Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_authExpiresAtKey);
  }
}
