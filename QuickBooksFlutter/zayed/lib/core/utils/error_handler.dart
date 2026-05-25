import 'package:dio/dio.dart';

class AppError {
  const AppError({required this.message, this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422 || statusCode == 400;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isNetwork => statusCode == null;

  @override
  String toString() => 'AppError($statusCode): $message';
}

// ─── Global parser — call from every datasource catch block ───────────
AppError parseError(DioException e) {
  // Network / timeout
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const AppError(message: 'انتهت مهلة الاتصال، حاول مجدداً');
  }
  if (e.type == DioExceptionType.connectionError) {
    return const AppError(message: 'تعذّر الاتصال بالخادم');
  }

  final response = e.response;
  if (response == null) {
    return AppError(message: e.message ?? 'خطأ غير معروف');
  }

  final statusCode = response.statusCode ?? 0;
  final body = response.data;
  final message = _extractMessage(body) ?? 'خطأ $statusCode';
  final errors = _extractErrors(body);

  return AppError(message: message, statusCode: statusCode, errors: errors);
}

String? _extractMessage(dynamic body) {
  if (body is Map<String, dynamic>) {
    return body['message'] as String? ??
        body['detail'] as String? ??
        body['title'] as String? ??
        body['error'] as String?;
  }
  if (body is String && body.isNotEmpty) return body;
  return null;
}

Map<String, List<String>>? _extractErrors(dynamic body) {
  if (body is! Map<String, dynamic>) return null;
  final errors = body['errors'];
  if (errors is! Map<String, dynamic>) return null;
  return errors.map(
    (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
  );
}
