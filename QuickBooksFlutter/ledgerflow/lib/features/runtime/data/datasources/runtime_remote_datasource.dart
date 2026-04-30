// runtime_remote_datasource.dart
// runtime_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_interceptors.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/runtime_model.dart';

class RuntimeRemoteDatasource {
  RuntimeRemoteDatasource(this._client);
  final ApiClient _client;

  Future<ApiResult<RuntimeModel>> getRuntime() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/settings/runtime',
      );
      return Success(RuntimeModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}