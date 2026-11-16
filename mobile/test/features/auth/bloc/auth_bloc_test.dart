import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';

class FakeAuthRepository extends AuthRepository {
  UserModel? currentUser;
  bool shouldThrow = false;
  String errorMessage = 'Authentication failed';

  @override
  Future<UserModel?> checkAuthStatus() async {
    if (shouldThrow) throw ApiException(message: errorMessage);
    return currentUser;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    if (shouldThrow) throw ApiException(message: errorMessage);
    final user = UserModel(
      id: 'mock-id-123',
      email: email,
      firstName: 'Alex',
      lastName: 'Mercer',
    );
    currentUser = user;
    return user;
  }

  @override
  Future<UserModel> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    if (shouldThrow) throw ApiException(message: errorMessage);
    final user = UserModel(
      id: 'mock-reg-id',
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
    currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthBloc authBloc;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    authBloc = AuthBloc(authRepository: fakeRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    test('AuthCheckRequested emits [AuthLoading, AuthAuthenticated] when session exists',
        () async {
      const activeUser = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Mercer',
      );
      fakeRepository.currentUser = activeUser;

      final expected = [
        const AuthLoading(),
        const AuthAuthenticated(activeUser),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthCheckRequested());
    });

    test('AuthCheckRequested emits [AuthLoading, AuthUnauthenticated] when no session',
        () async {
      fakeRepository.currentUser = null;

      final expected = [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthCheckRequested());
    });

    test('AuthCheckRequested emits [AuthLoading, AuthUnauthenticated] on exception',
        () async {
      fakeRepository.shouldThrow = true;

      final expected = [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthCheckRequested());
    });

    test('AuthLoginSubmitted emits [AuthLoading, AuthAuthenticated] on success',
        () async {
      final expected = [
        const AuthLoading(),
        const AuthAuthenticated(
          UserModel(
            id: 'mock-id-123',
            email: 'test@example.com',
            firstName: 'Alex',
            lastName: 'Mercer',
          ),
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const AuthLoginSubmitted(
          email: 'test@example.com',
          password: 'Password123!',
        ),
      );
    });

    test('AuthLoginSubmitted emits [AuthLoading, AuthFailure] on error',
        () async {
      fakeRepository.shouldThrow = true;
      fakeRepository.errorMessage = 'Invalid credentials';

      final expected = [
        const AuthLoading(),
        const AuthFailure('Invalid credentials'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const AuthLoginSubmitted(
          email: 'wrong@example.com',
          password: 'wrong',
        ),
      );
    });

    test('AuthRegisterSubmitted emits [AuthLoading, AuthAuthenticated] on success',
        () async {
      final expected = [
        const AuthLoading(),
        const AuthAuthenticated(
          UserModel(
            id: 'mock-reg-id',
            email: 'sarah@example.com',
            firstName: 'Sarah',
            lastName: 'Connor',
          ),
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const AuthRegisterSubmitted(
          firstName: 'Sarah',
          lastName: 'Connor',
          email: 'sarah@example.com',
          password: 'Password123!',
        ),
      );
    });

    test('AuthRegisterSubmitted emits [AuthLoading, AuthFailure] on error',
        () async {
      fakeRepository.shouldThrow = true;
      fakeRepository.errorMessage = 'Email already in use';

      final expected = [
        const AuthLoading(),
        const AuthFailure('Email already in use'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const AuthRegisterSubmitted(
          firstName: 'Sarah',
          lastName: 'Connor',
          email: 'sarah@example.com',
          password: 'Password123!',
        ),
      );
    });

    test('AuthLogoutRequested emits [AuthLoading, AuthUnauthenticated]',
        () async {
      final expected = [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthLogoutRequested());
    });
  });
}
