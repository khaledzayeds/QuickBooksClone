import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/utils/error_handler.dart';
import 'hotel_contracts_models.dart';

class HotelContractsDatasource {
  HotelContractsDatasource({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<ApiResult<List<HotelContractModel>>> getContracts() =>
      _getList('/api/hotels/contracts', HotelContractModel.fromJson);

  Future<ApiResult<HotelContractModel>> saveContract(HotelContractModel item) =>
      _save(
        '/api/hotels/contracts',
        item.id,
        item.toJson(),
        HotelContractModel.fromJson,
      );

  Future<ApiResult<List<HotelAllotmentModel>>> getAllotments() =>
      _getList('/api/hotels/allotments', HotelAllotmentModel.fromJson);

  Future<ApiResult<HotelAllotmentModel>> saveAllotment(
    HotelAllotmentModel item,
  ) => _save(
    '/api/hotels/allotments',
    item.id,
    item.toJson(),
    HotelAllotmentModel.fromJson,
  );

  Future<ApiResult<T>> setActive<T>(
    String endpoint,
    String id,
    bool isActive,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '$endpoint/$id/active',
        data: {'isActive': isActive},
      );
      return Success(fromJson(response.data ?? const {}));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<List<T>>> _getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await _client.get<List<dynamic>>(endpoint);
      return Success(
        (response.data ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList(),
      );
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<T>> _save<T>(
    String endpoint,
    String id,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = id.isEmpty
          ? await _client.post<Map<String, dynamic>>(endpoint, data: body)
          : await _client.put<Map<String, dynamic>>(
              '$endpoint/$id',
              data: body,
            );
      return Success(fromJson(response.data ?? const {}));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
