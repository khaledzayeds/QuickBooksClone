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
    if (_initialized) return;
    _dio = Dio(
      BaseOptions(
        baseUrl:        baseUrl ?? AppConstants.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      AppInterceptor(),
      LogInterceptor(
        requestBody:  true,
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

  void updateBaseUrl(String baseUrl) => _dio.options.baseUrl = baseUrl;

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

  Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? queryParameters}) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      _dio.delete<T>(path, data: data);
}