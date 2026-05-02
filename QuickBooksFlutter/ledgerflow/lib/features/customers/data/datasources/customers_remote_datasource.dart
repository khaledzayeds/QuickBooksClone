// customers_remote_datasource.dart
// customers_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/customer_model.dart';

class CustomersRemoteDatasource {
  CustomersRemoteDatasource(this._client);
  final ApiClient _client;

  Future<ApiResult<List<CustomerModel>>> getCustomers({
    String? search,
    bool includeInactive = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/customers',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'includeInactive': includeInactive,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data!['items'] as List)
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<CustomerModel>> getCustomer(String id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/api/customers/$id');
      return Success(CustomerModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<CustomerModel>> createCustomer(
      Map<String, dynamic> body) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/customers',
        data: body,
      );
      return Success(CustomerModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<CustomerModel>> updateCustomer(
      String id, Map<String, dynamic> body) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/api/customers/$id',
        data: body,
      );
      return Success(CustomerModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<CustomerModel>> toggleActive(
      String id, bool isActive) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/api/customers/$id/active',
        data: {'isActive': isActive},
      );
      return Success(CustomerModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}