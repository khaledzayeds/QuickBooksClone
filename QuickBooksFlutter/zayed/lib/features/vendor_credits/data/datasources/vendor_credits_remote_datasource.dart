// vendor_credits_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/vendor_credit_model.dart';

class VendorCreditsRemoteDatasource {
  VendorCreditsRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<VendorCreditModel>>> getAll({
    String? search,
    String? vendorId,
    int? action,
    bool includeVoid = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/vendor-credits',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
          'action': ?action,
          'includeVoid': includeVoid,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final credits = ((response.data?['items'] as List?) ?? const [])
          .map(
            (json) => VendorCreditModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      return Success(credits);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<VendorCreditModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/vendor-credits/$id',
      );
      return Success(VendorCreditModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<VendorCreditModel>> create(CreateVendorCreditDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/vendor-credits',
        data: dto.toJson(),
      );
      return Success(VendorCreditModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
