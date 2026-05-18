import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'api_interceptors.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  bool _initialized = false;
  String? _token;

  void init({String? baseUrl}) {
    final resolvedBaseUrl = _normalizeBaseUrl(
      baseUrl ?? AppConstants.defaultBaseUrl,
    );

    if (_initialized) {
      _dio.options.baseUrl = resolvedBaseUrl;
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: resolvedBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      AppInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugLog(obj.toString()),
      ),
    ]);
    _initialized = true;
  }

  Dio get dio {
    assert(_initialized, 'ApiClient.init() لازم يتحط في main.dart الأول');
    return _dio;
  }

  void updateBaseUrl(String baseUrl) {
    final resolvedBaseUrl = _normalizeBaseUrl(baseUrl);
    if (!_initialized) {
      init(baseUrl: resolvedBaseUrl);
      return;
    }
    _dio.options.baseUrl = resolvedBaseUrl;
  }

  String get currentBaseUrl => _initialized
      ? _dio.options.baseUrl
      : AppConstants.defaultBaseUrl;

  /// Called by AuthNotifier after successful login
  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Called by AuthNotifier on logout
  void clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
  }

  String? get currentToken => _token;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete<T>(path, data: data);

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return AppConstants.defaultBaseUrl;

    final withScheme = trimmed.startsWith('http://') ||
            trimmed.startsWith('https://')
        ? trimmed
        : 'http://$trimmed';

    return withScheme.endsWith('/')
        ? withScheme.substring(0, withScheme.length - 1)
        : withScheme;
  }
}
