import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [int? code]) : super(message, code);
}

class FileFailure extends Failure {
  const FileFailure(String message, [int? code]) : super(message, code);
}

class PlayerFailure extends Failure {
  const PlayerFailure(String message, [int? code]) : super(message, code);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, [int? code]) : super(message, code);
}
