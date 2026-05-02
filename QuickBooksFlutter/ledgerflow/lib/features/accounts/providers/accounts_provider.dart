// accounts_provider.dart
// accounts_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../data/datasources/accounts_remote_datasource.dart';
import '../data/models/account_model.dart';
import '../data/repositories/accounts_repository.dart';

// ─── Dependency Providers ─────────────────────────
final accountsDatasourceProvider = Provider<AccountsRemoteDatasource>(
  (ref) => AccountsRemoteDatasource(ApiClient.instance),
);

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref.watch(accountsDatasourceProvider)),
);

// ─── Accounts List ────────────────────────────────
final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<AccountModel>>(
  AccountsNotifier.new,
);

class AccountsNotifier extends AsyncNotifier<List<AccountModel>> {
  String _search = '';
  int? _typeFilter;
  bool _includeInactive = false;

  @override
  Future<List<AccountModel>> build() => _fetch();

  Future<List<AccountModel>> _fetch() async {
    final result = await ref.read(accountsRepositoryProvider).getAccounts(
          search: _search,
          accountType: _typeFilter,
          includeInactive: _includeInactive,
        );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  void setTypeFilter(int? type) {
    _typeFilter = type;
    refresh();
  }

  void setIncludeInactive(bool value) {
    _includeInactive = value;
    refresh();
  }

  // ─── Mutations ──────────────────────────────────
  Future<ApiResult<AccountModel>> createAccount(
      Map<String, dynamic> body) async {
    final result =
        await ref.read(accountsRepositoryProvider).createAccount(body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<AccountModel>> updateAccount(
      String id, Map<String, dynamic> body) async {
    final result =
        await ref.read(accountsRepositoryProvider).updateAccount(id, body);
    if (result.isSuccess) refresh();
    return result;
  }

  Future<ApiResult<AccountModel>> toggleActive(
      String id, bool isActive) async {
    final result =
        await ref.read(accountsRepositoryProvider).toggleActive(id, isActive);
    if (result.isSuccess) refresh();
    return result;
  }
}

// ─── Single Account ───────────────────────────────
final accountDetailProvider = FutureProvider.family<AccountModel, String>(
  (ref, id) async {
    final result =
        await ref.read(accountsRepositoryProvider).getAccount(id);
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  },
);