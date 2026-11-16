import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers verification of persisted session on app launch.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Dispatched when user submits the login form.
class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Dispatched when user submits the registration form.
class AuthRegisterSubmitted extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const AuthRegisterSubmitted({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, password];
}

/// Dispatched when user logs out.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
