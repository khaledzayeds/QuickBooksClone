// estimates_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/utils/error_handler.dart';
import '../models/estimate_model.dart';

class EstimatesRemoteDatasource {
  EstimatesRemoteDatasource(this._client);

  final ApiClient _client;

  Future<ApiResult<List<EstimateModel>>> getAll({
    String? search,
    String? customerId,
    bool includeClosed = false,
    bool includeCancelled = false,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/estimates',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
          'includeClosed': includeClosed,
          'includeCancelled': includeCancelled,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final estimates = ((response.data?['items'] as List?) ?? const [])
          .map((json) => EstimateModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(estimates);
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<EstimateModel>> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/estimates/$id');
      return Success(EstimateModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<EstimateModel>> create(CreateEstimateDto dto) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/estimates',
        data: dto.toJson(),
      );
      return Success(EstimateModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<EstimateModel>> send(String id) => _postAction(id, 'send');
  Future<ApiResult<EstimateModel>> accept(String id) => _postAction(id, 'accept');
  Future<ApiResult<EstimateModel>> decline(String id) => _postAction(id, 'decline');

  Future<ApiResult<EstimateModel>> cancel(String id) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>('/api/estimates/$id/cancel');
      return Success(EstimateModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<EstimateModel>> _postAction(String id, String action) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/api/estimates/$id/$action');
      return Success(EstimateModel.fromJson(response.data!));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
