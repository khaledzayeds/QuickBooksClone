import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/utils/error_handler.dart';
import 'hotel_reservations_models.dart';

class HotelReservationsDatasource {
  HotelReservationsDatasource({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<ApiResult<List<HotelReservationModel>>> getReservations() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/api/hotels/reservations',
      );
      return Success(
        (response.data ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HotelReservationModel.fromJson)
            .toList(),
      );
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<HotelReservationModel>> saveReservation(
    HotelReservationModel item,
  ) async {
    try {
      final response = item.id.isEmpty
          ? await _client.post<Map<String, dynamic>>(
              '/api/hotels/reservations',
              data: item.toJson(),
            )
          : await _client.put<Map<String, dynamic>>(
              '/api/hotels/reservations/${item.id}',
              data: item.toJson(),
            );
      return Success(HotelReservationModel.fromJson(response.data ?? const {}));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
