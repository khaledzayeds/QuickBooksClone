import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/utils/error_handler.dart';
import 'hotel_master_data_models.dart';

class HotelMasterDataDatasource {
  HotelMasterDataDatasource({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<ApiResult<List<HotelPropertyModel>>> getProperties() => _getList(
    '/api/hotels/master-data/properties',
    HotelPropertyModel.fromJson,
  );

  Future<ApiResult<HotelPropertyModel>> saveProperty(HotelPropertyModel item) =>
      _save(
        '/api/hotels/master-data/properties',
        item.id,
        item.toJson(),
        HotelPropertyModel.fromJson,
      );

  Future<ApiResult<List<HotelRoomTypeModel>>> getRoomTypes() => _getList(
    '/api/hotels/master-data/room-types',
    HotelRoomTypeModel.fromJson,
  );

  Future<ApiResult<HotelRoomTypeModel>> saveRoomType(HotelRoomTypeModel item) =>
      _save(
        '/api/hotels/master-data/room-types',
        item.id,
        item.toJson(),
        HotelRoomTypeModel.fromJson,
      );

  Future<ApiResult<List<HotelMealPlanModel>>> getMealPlans() => _getList(
    '/api/hotels/master-data/meal-plans',
    HotelMealPlanModel.fromJson,
  );

  Future<ApiResult<HotelMealPlanModel>> saveMealPlan(HotelMealPlanModel item) =>
      _save(
        '/api/hotels/master-data/meal-plans',
        item.id,
        item.toJson(),
        HotelMealPlanModel.fromJson,
      );

  Future<ApiResult<List<HotelAgentModel>>> getAgents() =>
      _getList('/api/hotels/master-data/agents', HotelAgentModel.fromJson);

  Future<ApiResult<HotelAgentModel>> saveAgent(HotelAgentModel item) => _save(
    '/api/hotels/master-data/agents',
    item.id,
    item.toJson(),
    HotelAgentModel.fromJson,
  );

  Future<ApiResult<T>> setActive<T extends HotelMasterDataRecord>(
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
