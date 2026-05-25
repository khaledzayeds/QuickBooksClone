// auth_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/auth_user.dart';
import '../models/login_user_option.dart';

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

  /// GET /api/auth/login-users
  Future<ApiResult<List<LoginUserOption>>> loginUsers() async {
    try {
      final r = await _client.get<List<dynamic>>('/api/auth/login-users');
      final data = r.data ?? const [];
      return Success(
        data
            .whereType<Map<String, dynamic>>()
            .map(LoginUserOption.fromJson)
            .toList(),
      );
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  /// GET /api/auth/me
  Future<ApiResult<AuthUser>> me() async {
    try {
      final r = await _client.get<Map<String, dynamic>>('/api/auth/me');
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
