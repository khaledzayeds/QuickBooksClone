// purchase_orders_remote_datasource.dart
// Aligned with backend: GET /api/purchase-orders uses includeClosed/includeCancelled,
// NOT a status string param.

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrdersRemoteDatasource {
  final _client = ApiClient.instance;

  /// GET /api/purchase-orders
  /// Query: search, vendorId, includeClosed, includeCancelled, page, pageSize
  Future<ApiResult<List<PurchaseOrderModel>>> getAll({
    String? search,
    String? vendorId,
    bool includeClosed    = false,
    bool includeCancelled = false,
    int page     = 1,
    int pageSize = 50,
  }) async {
    try {
      final r = await _client.get<dynamic>(
        '/api/purchase-orders',
        queryParameters: {
          if (search   != null && search.isNotEmpty) 'search': search,
          'vendorId': ?vendorId,
          'includeClosed':    includeClosed,
          'includeCancelled': includeCancelled,
          'page':     page,
          'pageSize': pageSize,
        },
      );

      // Response is PurchaseOrderListResponse: { items: [...], totalCount, page, pageSize }
      final data = r.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = (data['items'] ?? data['data'] ?? []) as List<dynamic>;
      } else {
        list = [];
      }

      return Success(
        list
            .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  /// GET /api/purchase-orders/{id}
  Future<ApiResult<PurchaseOrderModel>> getById(String id) async {
    try {
      final r = await _client
          .get<Map<String, dynamic>>('/api/purchase-orders/$id');
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  /// POST /api/purchase-orders
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

  /// POST /api/purchase-orders/{id}/open
  Future<ApiResult<PurchaseOrderModel>> openOrder(String id) async {
    try {
      final r = await _client
          .post<Map<String, dynamic>>('/api/purchase-orders/$id/open');
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  /// POST /api/purchase-orders/{id}/close
  Future<ApiResult<PurchaseOrderModel>> closeOrder(String id) async {
    try {
      final r = await _client
          .post<Map<String, dynamic>>('/api/purchase-orders/$id/close');
      return Success(PurchaseOrderModel.fromJson(r.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  /// PATCH /api/purchase-orders/{id}/cancel
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