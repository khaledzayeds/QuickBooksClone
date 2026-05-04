import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/error_handler.dart';
import 'models/settings_models.dart';

class SettingsRepository {
  SettingsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<RuntimeSettingsModel> getRuntime() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/settings/runtime');
      return RuntimeSettingsModel.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw parseError(error);
    }
  }

  Future<CompanySettingsModel?> getCompany() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/settings/company');
      return CompanySettingsModel.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      final parsed = parseError(error);
      if (parsed.isNotFound) return null;
      throw parsed;
    }
  }

  Future<CompanySettingsModel> updateCompany(CompanySettingsModel settings) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/settings/company',
        data: settings.toUpdateJson(),
      );
      return CompanySettingsModel.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw parseError(error);
    }
  }
}
