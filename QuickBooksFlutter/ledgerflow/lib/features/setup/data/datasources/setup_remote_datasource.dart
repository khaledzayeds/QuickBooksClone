import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/setup_models.dart';

class SetupRemoteDatasource {
  SetupRemoteDatasource({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<ApiResult<SetupStatus>> getStatus() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/setup/status',
      );
      return Success(SetupStatus.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InitializeCompanyResponse>> initializeCompany(
    InitializeCompanyRequest request,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/setup/initialize-company',
        data: request.toJson(),
      );
      return Success(InitializeCompanyResponse.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
