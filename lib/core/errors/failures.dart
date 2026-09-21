import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class HandleAlreadyTakenFailure extends Failure {
  const HandleAlreadyTakenFailure([super.message = 'This handle (@username) is already taken.']);
}

class InvalidHandleFailure extends Failure {
  const InvalidHandleFailure([super.message = 'Handle must be 3-20 characters long and contain only letters, numbers, or underscores.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed. Please check your internet connection.']);
}
