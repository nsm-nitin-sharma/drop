import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final UserEntity? user;
  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthSignInRequested extends AuthEvent {
  final String loginInput;
  final String password;

  const AuthSignInRequested({required this.loginInput, required this.password});

  @override
  List<Object?> get props => [loginInput, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String handle;
  final String displayName;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.handle,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, handle, displayName];
}

class AuthSignOutRequested extends AuthEvent {}
