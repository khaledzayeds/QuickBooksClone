// auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/models/auth_user.dart';
import '../data/models/login_user_option.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../companies/providers/company_registry_provider.dart';

final _authDatasourceProvider = Provider<AuthRemoteDatasource>(
  (_) => AuthRemoteDatasource(),
);

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  () => AuthNotifier(),
);

final loginUsersProvider = FutureProvider<List<LoginUserOption>>((ref) async {
  final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
  if (activeCompanyScope == null) return const [];
  final result = await ref.read(_authDatasourceProvider).loginUsers();
  return result.when(
    success: (users) => users,
    failure: (error) => throw Exception(error.message),
  );
});

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final activeCompanyScope = ref.watch(activeCompanyScopeProvider);
    if (activeCompanyScope == null) {
      ApiClient.instance.clearToken();
      return null;
    }

    final token = await StorageService.instance.readAuthToken(
      companyScope: activeCompanyScope,
    );
    if (token == null) {
      ApiClient.instance.clearToken();
      return null;
    }

    ApiClient.instance.setToken(token);
    final result = await ref.read(_authDatasourceProvider).me();
    return result.when(
      success: (user) {
        if (user.isExpired) {
          ApiClient.instance.clearToken();
          StorageService.instance.clearAuthSession(
            companyScope: activeCompanyScope,
          );
          return null;
        }

        StorageService.instance.saveAuthSession(
          companyScope: activeCompanyScope,
          token: user.token,
          expiresAt: user.expiresAt,
        );
        ApiClient.instance.setToken(user.token);
        return user;
      },
      failure: (_) {
        ApiClient.instance.clearToken();
        StorageService.instance.clearAuthSession(
          companyScope: activeCompanyScope,
        );
        return null;
      },
    );
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String userName, String password) async {
    final activeCompanyScope = ref.read(activeCompanyScopeProvider);
    if (activeCompanyScope == null) {
      return 'Choose a company before signing in.';
    }

    state = const AsyncLoading();
    final result = await ref
        .read(_authDatasourceProvider)
        .login(userName: userName, password: password);

    return result.when(
      success: (user) {
        ApiClient.instance.setToken(user.token);
        StorageService.instance.saveAuthSession(
          companyScope: activeCompanyScope,
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
    final activeCompanyScope = ref.read(activeCompanyScopeProvider);
    await ref.read(_authDatasourceProvider).logout();
    ApiClient.instance.clearToken();
    if (activeCompanyScope != null) {
      await StorageService.instance.clearAuthSession(
        companyScope: activeCompanyScope,
      );
    }
    state = const AsyncData(null);
  }
}
