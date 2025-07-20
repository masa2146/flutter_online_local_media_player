import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

abstract class Result<T> extends Equatable {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  List<Object?> get props => [failure];
}

// Extension methods for easier usage
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;
  Failure? get failure => isError ? (this as Error<T>).failure : null;

  R fold<R>(R Function(Failure) onError, R Function(T) onSuccess) {
    return isSuccess
        ? onSuccess((this as Success<T>).data)
        : onError((this as Error<T>).failure);
  }
}
