import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';

class MockAuthRepository extends AuthRepository {
  UserModel? mockUser;
  bool shouldThrow = false;
  String errorMessage = 'Invalid credentials';

  @override
  Future<UserModel> login(String email, String password) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage);
    }
    return mockUser ??
        const UserModel(
          id: 'user-id-99',
          email: 'alex@example.com',
          firstName: 'Alex',
          lastName: 'Mercer',
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
        child: LoginScreen(
          isModal: isModal,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders brand title, form fields, and action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(
        find.text('Sign in to your high-concurrency account'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('use_demo_customer_chip')), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('navigate_to_register_button')), findsOneWidget);
    });

    testWidgets('tapping demo customer chip auto-fills email and password',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byKey(const Key('use_demo_customer_chip')));
      await tester.pump();

      expect(find.text('customer@prismcommerce.com'), findsOneWidget);
      expect(find.text('Customer123!'), findsOneWidget);
    });

    testWidgets('toggling password visibility changes obscureText state',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      final passwordFieldFinder = find.byKey(const Key('login_password_field'));
      TextField textField = tester.widget<TextField>(
        find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);

      await tester.tap(find.byKey(const Key('login_password_toggle')));
      await tester.pump();

      textField = tester.widget<TextField>(
        find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isFalse);
    });

    testWidgets('validates required email and password fields on empty submit',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('validates invalid email format', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'invalid-email-format',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'ValidPass123!',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('successful login submits credentials and invokes onSuccess / pop',
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

      // Auto-fill demo credentials
      await tester.tap(find.byKey(const Key('use_demo_customer_chip')));
      await tester.pump();

      // Submit inside runAsync
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authBloc.state, isA<AuthAuthenticated>());
      expect(successCalled, isTrue);
    });

    testWidgets('displays error SnackBar when login fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockRepository.shouldThrow = true;
      mockRepository.errorMessage = 'Bad credentials provided';

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'alex@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'WrongPassword',
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Bad credentials provided'), findsOneWidget);
    });
  });
}
