// payments_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/payment_model.dart';

class PaymentsRemoteDatasource {
  PaymentsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<PaymentModel>>> getAll({
    String? search,
    String? customerId,
    String? invoiceId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/payments',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
          if (invoiceId != null && invoiceId.isNotEmpty) 'invoiceId': invoiceId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final payments = ((response.data?['items'] as List?) ?? const [])
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(payments);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<PaymentModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/payments/$id');
      return Success(PaymentModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<PaymentModel>> create(CreatePaymentDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/payments',
        data: dto.toJson(),
      );
      return Success(PaymentModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<List<PaymentModel>>> receive(ReceivePaymentDto dto) async {
    try {
      final response = await _client.post<List<dynamic>>(
        '/api/payments/receive',
        data: dto.toJson(),
      );
      final payments = (response.data ?? const [])
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(payments);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<PaymentModel>> voidPayment(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/payments/$id/void');
      return Success(PaymentModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
