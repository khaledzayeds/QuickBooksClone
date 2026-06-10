import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/utils/error_handler.dart';
import '../models/navigation_models.dart';

class NavigationDatasource {
  NavigationDatasource({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<ApiResult<List<NavigationMenuItem>>> getMenu() async {
    try {
      final response = await _client.get<List<dynamic>>('/api/navigation/menu');
      final data = response.data ?? const [];
      return Success(
        data
            .whereType<Map<String, dynamic>>()
            .map(NavigationMenuItem.fromJson)
            .toList(),
      );
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }

  Future<ApiResult<CurrentCompanyModules>> getCurrentModules() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/company-modules/current',
      );
      return Success(CurrentCompanyModules.fromJson(response.data ?? const {}));
    } on DioException catch (error) {
      return Failure(parseError(error));
    }
  }
}
