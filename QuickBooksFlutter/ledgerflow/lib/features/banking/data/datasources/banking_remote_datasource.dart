// banking_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/banking_models.dart';

class BankingRemoteDatasource {
  BankingRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<BankAccountModel>>> getAccounts() async {
    try {
      final response = await _client.get<List<dynamic>>('/api/banking/accounts');
      final list = (response.data ?? const [])
          .map((json) => BankAccountModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(list);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<BankRegisterResponseModel>> getRegister(String accountId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/banking/register',
        queryParameters: {'accountId': accountId},
      );
      return Success(BankRegisterResponseModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<void>> createTransfer(CreateBankTransferDto dto) async {
    try {
      await _client.post<Map<String, dynamic>>('/api/banking/transfers', data: dto.toJson());
      return const Success(null);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<void>> createDeposit(CreateBankDepositDto dto) async {
    try {
      await _client.post<Map<String, dynamic>>('/api/banking/deposits', data: dto.toJson());
      return const Success(null);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<void>> createCheck(CreateBankCheckDto dto) async {
    try {
      await _client.post<Map<String, dynamic>>('/api/banking/checks', data: dto.toJson());
      return const Success(null);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<BankReconcilePreviewModel>> previewReconcile(BankReconcilePreviewDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/banking/reconcile/preview',
        data: dto.toJson(),
      );
      return Success(BankReconcilePreviewModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
