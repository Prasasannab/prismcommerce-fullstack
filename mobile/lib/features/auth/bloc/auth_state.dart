import 'package:equatable/equatable.dart';
import '../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Indicates authentication operation in flight.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Indicates active authenticated user session.
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Indicates guest / unauthenticated status.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Indicates error occurred during login, registration, or session check.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
