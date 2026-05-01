// auth_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/auth_user.dart';

class AuthRemoteDatasource {
  final _client = ApiClient.instance;

  /// POST /api/auth/login
  Future<ApiResult<AuthUser>> login({
    required String userName,
    required String password,
  }) async {
    try {
      final r = await _client.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'userName': userName, 'password': password},
      );
      return Success(AuthUser.fromLoginResponse(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  /// POST /api/auth/logout
  Future<ApiResult<void>> logout() async {
    try {
      await _client.post<void>('/api/auth/logout');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
