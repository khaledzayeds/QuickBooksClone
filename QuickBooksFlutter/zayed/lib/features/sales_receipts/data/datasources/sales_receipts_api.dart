// sales_receipts_api.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../invoices/data/models/sales_preview_contracts.dart';
import '../models/sales_receipt_contracts.dart';

class SalesReceiptsApi {
  SalesReceiptsApi(this._client);
  final ApiClient _client;

  Future<ApiResult<List<SalesReceiptModel>>> getAll({
    String? search,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/sales-receipts',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data?['items'] as List? ?? [])
          .map((e) => SalesReceiptModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<SalesReceiptModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/sales-receipts/$id');
      return Success(SalesReceiptModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<SalesPostingPreviewModel>> preview(PreviewSalesReceiptDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/sales-receipts/preview',
        data: dto.toJson(),
      );
      return Success(SalesPostingPreviewModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<SalesReceiptModel>> create(CreateSalesReceiptDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/sales-receipts',
        data: dto.toJson(),
      );
      return Success(SalesReceiptModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<SalesReceiptModel>> voidReceipt(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/sales-receipts/$id/void');
      return Success(SalesReceiptModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
