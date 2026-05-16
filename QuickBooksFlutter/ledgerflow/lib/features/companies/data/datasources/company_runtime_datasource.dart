import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/company_runtime_models.dart';

class CompanyRuntimeDatasource {
  CompanyRuntimeDatasource({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<ApiResult<ActiveCompanyRuntimeModel>> getActive() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/companies/active');
      return Success(ActiveCompanyRuntimeModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<ActiveCompanyRuntimeModel>> open(OpenCompanyRuntimeRequest request) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/companies/open',
        data: request.toJson(),
      );
      return Success(ActiveCompanyRuntimeModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<ActiveCompanyRuntimeModel>> close() async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/api/companies/close');
      return Success(ActiveCompanyRuntimeModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
