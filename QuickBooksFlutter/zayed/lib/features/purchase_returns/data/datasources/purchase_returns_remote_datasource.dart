// purchase_returns_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/purchase_return_model.dart';

class PurchaseReturnsRemoteDatasource {
  PurchaseReturnsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<PurchaseReturnModel>>> getAll({
    String? search,
    String? purchaseBillId,
    String? vendorId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/purchase-returns',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (purchaseBillId != null && purchaseBillId.isNotEmpty) 'purchaseBillId': purchaseBillId,
          if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final returns = ((response.data?['items'] as List?) ?? const [])
          .map((json) => PurchaseReturnModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(returns);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<PurchaseReturnModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/purchase-returns/$id');
      return Success(PurchaseReturnModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<PurchaseReturnModel>> create(CreatePurchaseReturnDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/purchase-returns',
        data: dto.toJson(),
      );
      return Success(PurchaseReturnModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<PurchaseReturnModel>> voidReturn(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/purchase-returns/$id/void');
      return Success(PurchaseReturnModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
