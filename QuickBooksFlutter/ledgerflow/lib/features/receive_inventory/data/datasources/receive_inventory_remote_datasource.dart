// receive_inventory_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/create_receive_inventory_dto.dart';
import '../models/receive_inventory_model.dart';
import '../models/receiving_plan_model.dart';

class ReceiveInventoryRemoteDatasource {
  final _client = ApiClient.instance;

  Future<ApiResult<List<ReceiveInventoryModel>>> getAll({
    String? purchaseOrderId,
    String? vendorId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        '/api/receive-inventory',
        queryParameters: {
          'purchaseOrderId': ?purchaseOrderId,
          'vendorId': ?vendorId,
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
            .map((e) => ReceiveInventoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<ReceiveInventoryModel>> getById(String id) async {
    try {
      final r = await _client.get<Map<String, dynamic>>('/api/receive-inventory/$id');
      return Success(ReceiveInventoryModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<ReceiveInventoryModel>> create(CreateReceiveInventoryDto dto) async {
    try {
      final r = await _client.post<Map<String, dynamic>>(
        '/api/receive-inventory',
        data: dto.toJson(),
      );
      return Success(ReceiveInventoryModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<ReceivingPlanModel>> getReceivingPlan(String poId) async {
    try {
      final r = await _client.get<Map<String, dynamic>>('/api/purchase-orders/$poId/receiving-plan');
      return Success(ReceivingPlanModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
