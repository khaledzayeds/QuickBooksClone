import 'package:dio/dio.dart';

class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // final token = StorageService.instance.token;
    // if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Logging فقط — الـ parsing بيتعمل في الـ datasource
    debugLog('❌ [${err.response?.statusCode}] ${err.requestOptions.path}');
    handler.next(err);
  }
}

void debugLog(String msg) {
  assert(() {
    // ignore: avoid_print
    print(msg);
    return true;
  }());
}
