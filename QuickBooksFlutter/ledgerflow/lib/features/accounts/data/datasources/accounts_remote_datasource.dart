// accounts_remote_datasource.dart
// accounts_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/account_model.dart';

class AccountsRemoteDatasource {
  AccountsRemoteDatasource(this._client);
  final ApiClient _client;

  // ─── List ──────────────────────────────────────
  Future<ApiResult<List<AccountModel>>> getAccounts({
    String? search,
    int? accountType,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/accounts',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'accountType': ?accountType,
          'includeInactive': includeInactive,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data!['items'] as List)
          .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  // ─── Get by ID ────────────────────────────────
  Future<ApiResult<AccountModel>> getAccount(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/api/accounts/$id');
      return Success(AccountModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  // ─── Create ───────────────────────────────────
  Future<ApiResult<AccountModel>> createAccount(
      Map<String, dynamic> body) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/accounts',
        data: body,
      );
      return Success(AccountModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  // ─── Update ───────────────────────────────────
  Future<ApiResult<AccountModel>> updateAccount(
      String id, Map<String, dynamic> body) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/api/accounts/$id',
        data: body,
      );
      return Success(AccountModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  // ─── Toggle Active ────────────────────────────
  Future<ApiResult<AccountModel>> toggleActive(
      String id, bool isActive) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/api/accounts/$id/active',
        data: {'isActive': isActive},
      );
      return Success(AccountModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}