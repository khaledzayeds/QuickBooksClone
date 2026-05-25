import '../utils/error_handler.dart';

sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => switch (this) {
        Success<T>(data: final d) => d,
        Failure<T>()             => null,
      };

  AppError? get error => switch (this) {
        Success<T>()              => null,
        Failure<T>(error: final e) => e,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError e) failure,
  }) =>
      switch (this) {
        Success<T>(data: final d)  => success(d),
        Failure<T>(error: final e) => failure(e),
      };

  void fold({
    void Function(T data)? onSuccess,
    void Function(AppError error)? onFailure,
  }) {
    switch (this) {
      case Success<T>(data: final d):
        onSuccess?.call(d);
      case Failure<T>(error: final e):
        onFailure?.call(e);
    }
  }
}

final class Success<T> extends ApiResult<T> {
  const Success(this.data);
  @override
  final T data;
}

final class Failure<T> extends ApiResult<T> {
  const Failure(this.error);
  @override
  final AppError error;
}