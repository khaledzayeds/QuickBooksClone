// purchase_bills_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/purchase_bill_model.dart';
import '../models/billing_plan_model.dart';
import '../models/create_purchase_bill_dto.dart';

class PurchaseBillsRemoteDatasource {
  PurchaseBillsRemoteDatasource(this._client);
  final ApiClient _client;

  Future<ApiResult<List<PurchaseBillModel>>> getBills({
    String? search,
    String? vendorId,
    String? inventoryReceiptId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/purchase-bills',
        queryParameters: {
          'search': ?search,
          'vendorId': ?vendorId,
          'inventoryReceiptId': ?inventoryReceiptId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data!['items'] as List)
          .map((e) => PurchaseBillModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseBillModel>> getBill(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/purchase-bills/$id');
      return Success(PurchaseBillModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<BillingPlanModel>> getBillingPlan(String inventoryReceiptId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/receive-inventory/$inventoryReceiptId/billing-plan',
      );
      return Success(BillingPlanModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseBillModel>> createBill(CreatePurchaseBillDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/purchase-bills',
        data: dto.toJson(),
      );
      return Success(PurchaseBillModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<PurchaseBillModel>> voidBill(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/purchase-bills/$id/void');
      return Success(PurchaseBillModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
