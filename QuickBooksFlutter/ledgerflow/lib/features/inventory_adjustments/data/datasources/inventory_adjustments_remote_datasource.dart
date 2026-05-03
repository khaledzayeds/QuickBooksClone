// inventory_adjustments_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/inventory_adjustment_model.dart';

class InventoryAdjustmentsRemoteDatasource {
  InventoryAdjustmentsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<InventoryAdjustmentModel>>> getAll({
    String? search,
    String? itemId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/inventory-adjustments',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (itemId != null && itemId.isNotEmpty) 'itemId': itemId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final items = ((response.data?['items'] as List?) ?? const [])
          .map((json) => InventoryAdjustmentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InventoryAdjustmentModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/inventory-adjustments/$id');
      return Success(InventoryAdjustmentModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InventoryAdjustmentModel>> create(CreateInventoryAdjustmentDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/inventory-adjustments',
        data: dto.toJson(),
      );
      return Success(InventoryAdjustmentModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
