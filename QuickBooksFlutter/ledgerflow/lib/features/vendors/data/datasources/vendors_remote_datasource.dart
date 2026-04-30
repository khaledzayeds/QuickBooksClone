// vendors_remote_datasource.dart
// vendors_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_interceptors.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/vendor_model.dart';

class VendorsRemoteDatasource {
  VendorsRemoteDatasource(this._client);
  final ApiClient _client;

  Future<ApiResult<List<VendorModel>>> getVendors({
    String? search,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/vendors',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'includeInactive': includeInactive,
          'page':     page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data!['items'] as List)
          .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<VendorModel>> getVendor(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/api/vendors/$id');
      return Success(VendorModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<VendorModel>> createVendor(
      Map<String, dynamic> body) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/vendors',
        data: body,
      );
      return Success(VendorModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<VendorModel>> updateVendor(
      String id, Map<String, dynamic> body) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/api/vendors/$id',
        data: body,
      );
      return Success(VendorModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<VendorModel>> toggleActive(
      String id, bool isActive) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/api/vendors/$id/active',
        data: {'isActive': isActive},
      );
      return Success(VendorModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}