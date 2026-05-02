// vendor_payments_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/vendor_payment_model.dart';

class VendorPaymentsRemoteDatasource {
  VendorPaymentsRemoteDatasource(this._client);
  final ApiClient _client;

  Future<ApiResult<List<VendorPaymentModel>>> getPayments({
    String? search,
    String? vendorId,
    String? purchaseBillId,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/vendor-payments',
        queryParameters: {
          'search': ?search,
          'vendorId': ?vendorId,
          'purchaseBillId': ?purchaseBillId,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final items = (response.data!['items'] as List)
          .map((e) => VendorPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<VendorPaymentModel>> createPayment(Map<String, dynamic> body) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/vendor-payments',
        data: body,
      );
      return Success(VendorPaymentModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }

  Future<ApiResult<VendorPaymentModel>> voidPayment(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/vendor-payments/$id/void');
      return Success(VendorPaymentModel.fromJson(response.data!));
    } on DioException catch (e) {
      return Failure(parseError(e));
    }
  }
}
