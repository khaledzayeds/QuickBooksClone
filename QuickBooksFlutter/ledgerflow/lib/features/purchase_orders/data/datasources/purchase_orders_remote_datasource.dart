import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrdersRemoteDatasource {
  final _client = ApiClient.instance;

  Future<ApiResult<List<PurchaseOrderModel>>> getAll({
    String? status,
    String? vendorId,
    int page  = 1,
    int limit = 50,
  }) async {
    try {
      final r = await _client.get<dynamic>(
        '/api/purchase-orders',
        queryParameters: {
          if (status   != null) 'status':   status,
          if (vendorId != null) 'vendorId': vendorId,
          'page':  page,
          'limit': limit,
        },
      );
      final data = r.data;
      final list = (data is List
          ? data
          : (data['items'] ?? data['data'] ?? [])) as List<dynamic>;
      return Success(
        list.map((e) =>
            PurchaseOrderModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseOrderModel>> getById(String id) async {
    try {
      final r = await _client
          .get<Map<String, dynamic>>('/api/purchase-orders/$id');
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseOrderModel>> create(
      CreatePurchaseOrderDto dto) async {
    try {
      final r = await _client.post<Map<String, dynamic>>(
        '/api/purchase-orders',
        data: dto.toJson(),
      );
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseOrderModel>> openOrder(String id) async {
    try {
      final r = await _client
          .post<Map<String, dynamic>>('/api/purchase-orders/$id/open');
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseOrderModel>> closeOrder(String id) async {
    try {
      final r = await _client
          .post<Map<String, dynamic>>('/api/purchase-orders/$id/close');
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseOrderModel>> cancelOrder(String id) async {
    try {
      final r = await _client
          .patch<Map<String, dynamic>>('/api/purchase-orders/$id/cancel');
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<void>> delete(String id) async {
    try {
      await _client.delete<void>('/api/purchase-orders/$id');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}