// customer_credits_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/customer_credit_model.dart';

class CustomerCreditsRemoteDatasource {
  CustomerCreditsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<CustomerCreditModel>>> getAll({
    String? search,
    String? customerId,
    int? action,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/customer-credits',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty)
            'customerId': customerId,
          'action': ?action,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final credits = ((response.data?['items'] as List?) ?? const [])
          .map(
            (json) =>
                CustomerCreditModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      return Success(credits);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<CustomerCreditModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/customer-credits/$id',
      );
      return Success(CustomerCreditModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<CustomerCreditModel>> create(
    CreateCustomerCreditDto dto,
  ) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/customer-credits',
        data: dto.toJson(),
      );
      return Success(CustomerCreditModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<CustomerCreditModel>> post(String id) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/customer-credits/$id/post',
      );
      return Success(CustomerCreditModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
