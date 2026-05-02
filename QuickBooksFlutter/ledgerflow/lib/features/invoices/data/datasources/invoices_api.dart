// invoices_api.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/invoice_contracts.dart';

class InvoicesApi {
  InvoicesApi(this._client);
  final ApiClient _client;

  Future<ApiResult<List<InvoiceModel>>> getAll({
    String? search,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/invoices',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data?['items'] as List? ?? [])
          .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<InvoiceModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/invoices/$id');
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<InvoiceModel>> create(CreateInvoiceDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/invoices',
        data: dto.toJson(),
      );
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<InvoiceModel>> postInvoice(String id) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/api/invoices/$id/post');
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<void>> markSent(String id) async {
    try {
      await _client.patch<void>('/api/invoices/$id/sent');
      return const Success(null);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<InvoiceModel>> voidInvoice(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/invoices/$id/void');
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
