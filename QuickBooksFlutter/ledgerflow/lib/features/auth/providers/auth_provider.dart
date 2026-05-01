// auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/models/auth_user.dart';
import '../../../../core/api/api_client.dart';

final _authDatasourceProvider = Provider<AuthRemoteDatasource>(
  (_) => AuthRemoteDatasource(),
);

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async => null;

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String userName, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(_authDatasourceProvider)
        .login(userName: userName, password: password);

    return result.when(
      success: (user) {
        ApiClient.instance.setToken(user.token);
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
    state = const AsyncData(null);
  }
}
