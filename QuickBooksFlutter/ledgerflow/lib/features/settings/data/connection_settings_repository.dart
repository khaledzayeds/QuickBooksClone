import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final model = ConnectionSettingsModel.fromStorage({
      'profileType': prefs.getString(_profileTypeKey),
      'baseUrl': prefs.getString(_baseUrlKey),
      'lanHost': prefs.getString(_lanHostKey),
      'hostedUrl': prefs.getString(_hostedUrlKey),
      'customUrl': prefs.getString(_customUrlKey),
    });

    _apiClient.updateBaseUrl(model.baseUrl);
    return model;
  }

  Future<ConnectionSettingsModel> save(ConnectionSettingsModel settings) async {
    final resolved = settings.resolveBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    final values = resolved.toStorage();

    await prefs.setString(_profileTypeKey, values['profileType'] ?? ConnectionProfileType.local.name);
    await prefs.setString(_baseUrlKey, values['baseUrl'] ?? ConnectionSettingsModel.defaultLocalUrl);
    await prefs.setString(_lanHostKey, values['lanHost'] ?? '');
    await prefs.setString(_hostedUrlKey, values['hostedUrl'] ?? '');
    await prefs.setString(_customUrlKey, values['customUrl'] ?? '');

    _apiClient.updateBaseUrl(resolved.baseUrl);
    return resolved;
  }

  Future<ConnectionTestResult> test(ConnectionSettingsModel settings) async {
    final resolved = settings.resolveBaseUrl();
    final previousBaseUrl = _apiClient.dio.options.baseUrl;
    _apiClient.updateBaseUrl(resolved.baseUrl);

    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/settings/runtime');
      final provider = response.data?['databaseProvider'] ?? response.data?['provider'] ?? 'unknown database';
      return ConnectionTestResult(
        success: true,
        message: 'Connection OK. Database provider: $provider',
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
}
