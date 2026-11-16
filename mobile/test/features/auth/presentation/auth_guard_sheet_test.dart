import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_guard_sheet.dart';

class StubAuthRepository extends AuthRepository {
  UserModel? user;

  @override
  Future<UserModel?> checkAuthStatus() async => user;

  @override
  Future<UserModel> login(String email, String password) async {
    user = const UserModel(
      id: 'stub-user-1',
      email: 'customer@prismcommerce.com',
      firstName: 'Alex',
      lastName: 'Mercer',
    );
    return user!;
  }
}

void main() {
  late StubAuthRepository stubRepository;
  late AuthBloc authBloc;

  setUp(() {
    stubRepository = StubAuthRepository();
    authBloc = AuthBloc(authRepository: stubRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthGuardSheet', () {
    testWidgets('returns true immediately without showing sheet if already authenticated',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool? guardResult;

      // Seed authenticated state
      authBloc.emit(
        const AuthAuthenticated(
          UserModel(
            id: 'u-1',
            email: 'auth@example.com',
            firstName: 'Auth',
            lastName: 'User',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  key: const Key('trigger_guard_button'),
                  onPressed: () async {
                    guardResult = await AuthGuardSheet.show(context);
                  },
                  child: const Text('Check Auth'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('trigger_guard_button')));
      await tester.pump();

      expect(guardResult, isTrue);
      // No bottom sheet or LoginScreen was presented
      expect(find.text('Welcome Back'), findsNothing);
    });

    testWidgets('presents bottom sheet with LoginScreen if unauthenticated',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool? guardResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  key: const Key('trigger_guard_button'),
                  onPressed: () async {
                    guardResult = await AuthGuardSheet.show(context);
                  },
                  child: const Text('Check Auth'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('trigger_guard_button')));
      await tester.pumpAndSettle();

      // Bottom sheet is displayed with LoginScreen
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byKey(const Key('use_demo_customer_chip')), findsOneWidget);

      // Auto-fill and sign in
      await tester.tap(find.byKey(const Key('use_demo_customer_chip')));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await tester.pump();
      await tester.pumpAndSettle();

      expect(guardResult, isTrue);
    });
  });
}
