import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/create_receive_inventory_dto.dart';
import '../models/receive_inventory_model.dart';

class ReceiveInventoryRemoteDatasource {
  final _client = ApiClient.instance;

  Future<ApiResult<List<ReceiveInventoryModel>>> getAll({
    String? purchaseOrderId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/receive-inventory',
        queryParameters: {
          if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      final list = (data is List
          ? data
          : (data['items'] ?? data['data'] ?? [])) as List<dynamic>;

      return Success(
        list
            .map((item) =>
                ReceiveInventoryModel.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<ReceiveInventoryModel>> getById(String id) async {
    try {
      final response = await _client
          .get<Map<String, dynamic>>('/api/receive-inventory/$id');
      return Success(ReceiveInventoryModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<ReceiveInventoryModel>> create(
    CreateReceiveInventoryDto dto,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/receive-inventory',
        data: dto.toJson(),
      );
      return Success(ReceiveInventoryModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
