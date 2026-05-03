// sales_returns_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/sales_return_model.dart';

class SalesReturnsRemoteDatasource {
  SalesReturnsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<SalesReturnModel>>> getAll({
    String? search,
    String? invoiceId,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/sales-returns',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (invoiceId != null && invoiceId.isNotEmpty) 'invoiceId': invoiceId,
          if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final returns = ((response.data?['items'] as List?) ?? const [])
          .map((json) => SalesReturnModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(returns);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesReturnModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/sales-returns/$id');
      return Success(SalesReturnModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesReturnModel>> create(CreateSalesReturnDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/sales-returns',
        data: dto.toJson(),
      );
      return Success(SalesReturnModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesReturnModel>> post(String id) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/api/sales-returns/$id/post');
      return Success(SalesReturnModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesReturnModel>> voidReturn(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/sales-returns/$id/void');
      return Success(SalesReturnModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
