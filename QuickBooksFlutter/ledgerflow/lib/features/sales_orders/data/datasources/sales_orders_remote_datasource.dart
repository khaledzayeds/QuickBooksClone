// sales_orders_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../models/sales_order_model.dart';

class SalesOrdersRemoteDatasource {
  SalesOrdersRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<SalesOrderModel>>> getAll({
    String? search,
    String? customerId,
    bool includeClosed = false,
    bool includeCancelled = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/sales-orders',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty)
            'customerId': customerId,
          'includeClosed': includeClosed,
          'includeCancelled': includeCancelled,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final orders = ((response.data?['items'] as List?) ?? const [])
          .map((json) => SalesOrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(orders);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesOrderModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/sales-orders/$id',
      );
      return Success(SalesOrderModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesOrderModel>> create(CreateSalesOrderDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/sales-orders',
        data: dto.toJson(),
      );
      return Success(SalesOrderModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesOrderModel>> open(String id) => _postAction(id, 'open');
  Future<ApiResult<SalesOrderModel>> close(String id) =>
      _postAction(id, 'close');

  Future<ApiResult<SalesOrderModel>> cancel(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/api/sales-orders/$id/cancel',
      );
      return Success(SalesOrderModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<InvoiceModel>> convertToInvoice(String id) async {
    final today = DateTime.now();
    final due = today.add(const Duration(days: 30));
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/sales-orders/$id/convert-to-invoice',
        data: {
          'invoiceDate': _dateOnly(today),
          'dueDate': _dateOnly(due),
          'saveMode': 2,
          'lines': <Map<String, dynamic>>[],
        },
      );
      return Success(InvoiceModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<SalesOrderModel>> _postAction(
    String id,
    String action,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/sales-orders/$id/$action',
      );
      return Success(SalesOrderModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
