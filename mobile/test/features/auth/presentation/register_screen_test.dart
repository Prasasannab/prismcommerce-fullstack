import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';

class MockAuthRepository extends AuthRepository {
  UserModel? mockUser;
  bool shouldThrow = false;
  String errorMessage = 'Registration error';

  @override
  Future<UserModel> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage);
    }
    return mockUser ??
        UserModel(
          id: 'new-user-id',
          email: email,
          firstName: firstName,
          lastName: lastName,
        );
  }
}

void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  Widget buildSubject({bool isModal = false, VoidCallback? onSuccess}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: RegisterScreen(
          isModal: isModal,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  group('RegisterScreen', () {
    testWidgets('renders all registration form fields and buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      // Header title + submit button label
      expect(find.text('Create Account'), findsNWidgets(2));
      expect(find.byKey(const Key('register_first_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_last_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(
        find.byKey(const Key('register_confirm_password_field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('navigate_to_login_button')), findsOneWidget);
    });

    testWidgets('validates required fields on empty submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      expect(find.text('Required'), findsNWidgets(2));
      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Please enter a password.'), findsOneWidget);
      expect(find.text('Please confirm your password.'), findsOneWidget);
    });

    testWidgets('validates password mismatch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('register_first_name_field')),
        'Sam',
      );
      await tester.enterText(
        find.byKey(const Key('register_last_name_field')),
        'Fisher',
      );
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'sam@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'Secret123!',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'Secret456!',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('submits registration successfully when form is valid',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool successCalled = false;
      await tester.pumpWidget(
        buildSubject(
          isModal: true,
          onSuccess: () {
            successCalled = true;
          },
        ),
      );

      await tester.enterText(
        find.byKey(const Key('register_first_name_field')),
        'Sam',
      );
      await tester.enterText(
        find.byKey(const Key('register_last_name_field')),
        'Fisher',
      );
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'sam@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'Secret123!',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'Secret123!',
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('register_submit_button')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authBloc.state, isA<AuthAuthenticated>());
      expect(successCalled, isTrue);
    });

    testWidgets('displays error SnackBar on registration failure',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockRepository.shouldThrow = true;
      mockRepository.errorMessage = 'Email already registered';

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('register_first_name_field')),
        'Sam',
      );
      await tester.enterText(
        find.byKey(const Key('register_last_name_field')),
        'Fisher',
      );
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'existing@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'Secret123!',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'Secret123!',
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('register_submit_button')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Email already registered'), findsOneWidget);
    });
  });
}
