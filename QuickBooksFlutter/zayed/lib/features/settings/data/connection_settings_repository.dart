import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_handler.dart';
import 'models/connection_settings_model.dart';

class ConnectionSettingsRepository {
  ConnectionSettingsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  static const _profileTypeKey = 'connection.profileType';
  static const _baseUrlKey = 'connection.baseUrl';
  static const _lanHostKey = 'connection.lanHost';
  static const _hostedUrlKey = 'connection.hostedUrl';
  static const _customUrlKey = 'connection.customUrl';

  final ApiClient _apiClient;

  Future<ConnectionSettingsModel> load() async {
    final settings = ConnectionSettingsModel.defaults();
    _apiClient.updateBaseUrl(settings.baseUrl);
    await _persistOfflineDefaults(settings);
    return settings;
  }

  Future<ConnectionSettingsModel> save(ConnectionSettingsModel settings) async {
    final resolved = ConnectionSettingsModel.defaults();
    _apiClient.updateBaseUrl(resolved.baseUrl);
    await _persistOfflineDefaults(resolved);
    return resolved;
  }

  Future<ConnectionTestResult> test(ConnectionSettingsModel settings) async {
    final resolved = ConnectionSettingsModel.defaults();
    final previousBaseUrl = _apiClient.dio.options.baseUrl;
    _apiClient.updateBaseUrl(resolved.baseUrl);

    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/settings/runtime');
      final provider = response.data?['databaseProvider'] ?? response.data?['provider'] ?? 'unknown database';
      return ConnectionTestResult(
        success: true,
        message: '${AppConstants.appDisplayName} local runtime is ready. Database provider: $provider',
      );
    } on DioException catch (error) {
      final parsed = parseError(error);
      return ConnectionTestResult(success: false, message: parsed.message);
    } catch (error) {
      return ConnectionTestResult(success: false, message: error.toString());
    } finally {
      _apiClient.updateBaseUrl(previousBaseUrl);
    }
  }

  Future<void> _persistOfflineDefaults(ConnectionSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileTypeKey, ConnectionProfileType.local.name);
    await prefs.setString(_baseUrlKey, settings.baseUrl);
    await prefs.setString(_lanHostKey, '');
    await prefs.setString(_hostedUrlKey, '');
    await prefs.setString(_customUrlKey, '');
  }
}
