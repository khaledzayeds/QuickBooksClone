// auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/models/auth_user.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/storage_service.dart';

final _authDatasourceProvider = Provider<AuthRemoteDatasource>(
  (_) => AuthRemoteDatasource(),
);

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  () => AuthNotifier(),
);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final token = await StorageService.instance.readAuthToken();
    if (token == null) return null;

    ApiClient.instance.setToken(token);
    final result = await ref.read(_authDatasourceProvider).me();
    return result.when(
      success: (user) {
        if (user.isExpired) {
          ApiClient.instance.clearToken();
          StorageService.instance.clearAuthSession();
          return null;
        }

        StorageService.instance.saveAuthSession(
          token: user.token,
          expiresAt: user.expiresAt,
        );
        ApiClient.instance.setToken(user.token);
        return user;
      },
      failure: (_) {
        ApiClient.instance.clearToken();
        StorageService.instance.clearAuthSession();
        return null;
      },
    );
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String userName, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(_authDatasourceProvider)
        .login(userName: userName, password: password);

    return result.when(
      success: (user) {
        ApiClient.instance.setToken(user.token);
        StorageService.instance.saveAuthSession(
          token: user.token,
          expiresAt: user.expiresAt,
        );
        state = AsyncData(user);
        return null;
      },
      failure: (e) {
        state = const AsyncData(null);
        return e.message;
      },
    );
  }

  Future<void> logout() async {
    await ref.read(_authDatasourceProvider).logout();
    ApiClient.instance.clearToken();
    await StorageService.instance.clearAuthSession();
    state = const AsyncData(null);
  }
}
