// invoices_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/invoice_model.dart';

class InvoicesRemoteDatasource {
  InvoicesRemoteDatasource(this._client, {this.salesReceiptMode = false});

  final ApiClient _client;
  final bool salesReceiptMode;

  String get _basePath => salesReceiptMode ? '/api/sales-receipts' : '/api/invoices';

  Future<ApiResult<List<InvoiceModel>>> getInvoices({
    String? search,
    String? customerId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        _basePath,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final invoices = ((response.data?['items'] as List?) ?? const [])
          .map((json) => InvoiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(invoices);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InvoiceModel>> getInvoice(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('$_basePath/$id');
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InvoiceModel>> createInvoice(Map<String, dynamic> body) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(_basePath, data: body);
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InvoiceModel>> postInvoice(String id) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/api/invoices/$id/post');
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InvoiceModel>> voidInvoice(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('$_basePath/$id/void');
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
