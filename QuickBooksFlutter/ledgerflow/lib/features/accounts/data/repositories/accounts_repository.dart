// accounts_repository.dart
// accounts_repository.dart

import '../../../../core/api/api_result.dart';
import '../datasources/accounts_remote_datasource.dart';
import '../models/account_model.dart';

class AccountsRepository {
  AccountsRepository(this._datasource);
  final AccountsRemoteDatasource _datasource;

  Future<ApiResult<List<AccountModel>>> getAccounts({
    String? search,
    int? accountType,
    bool includeInactive = false,
  }) =>
      _datasource.getAccounts(
        search: search,
        accountType: accountType,
        includeInactive: includeInactive,
      );

  Future<ApiResult<AccountModel>> getAccount(String id) =>
      _datasource.getAccount(id);

  Future<ApiResult<AccountModel>> createAccount(
          Map<String, dynamic> body) =>
      _datasource.createAccount(body);

  Future<ApiResult<AccountModel>> updateAccount(
          String id, Map<String, dynamic> body) =>
      _datasource.updateAccount(id, body);

  Future<ApiResult<AccountModel>> toggleActive(
          String id, bool isActive) =>
      _datasource.toggleActive(id, isActive);
}