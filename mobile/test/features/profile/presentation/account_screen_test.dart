import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_cubit.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/profile/presentation/screens/account_screen.dart';

class MockAuthRepository extends AuthRepository {
  UserModel? currentUser;

  @override
  Future<UserModel?> checkAuthStatus() async {
    return currentUser;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ThemeCubit themeCubit;
  late AuthBloc authBloc;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp('hive_test_acc_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>('${StorageService.settingsBoxName}_acc');
    final cartBox =
        await Hive.openBox<dynamic>('${StorageService.cartBoxName}_acc');
    StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    themeCubit = ThemeCubit(storageService: StorageService.instance);
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
    themeCubit.close();
  });

  Widget buildSubject({
    VoidCallback? onNavigateToOrders,
    VoidCallback? onNavigateToShop,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: AccountScreen(
          onNavigateToOrders: onNavigateToOrders,
          onNavigateToShop: onNavigateToShop,
        ),
      ),
    );
  }

  group('AccountScreen Unauthenticated', () {
    testWidgets('renders guest welcome prompt, auth buttons, and theme switch',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authBloc.emit(const AuthUnauthenticated());

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Account'), findsOneWidget);
      expect(find.text('Welcome to PrismCommerce'), findsOneWidget);
      expect(
        find.text(
          'Sign in to track orders, save shipping addresses, and unlock member discounts.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('account_sign_in_button')), findsOneWidget);
      expect(find.byKey(const Key('account_register_button')), findsOneWidget);
      expect(find.byKey(const Key('account_theme_switch')), findsOneWidget);
    });

    testWidgets('toggles theme when switch is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authBloc.emit(const AuthUnauthenticated());

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final initialMode = themeCubit.state;
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('account_theme_switch')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(themeCubit.state, isNot(initialMode));
    });
  });

  group('AccountScreen Authenticated', () {
    const testUser = UserModel(
      id: 'usr-4412',
      email: 'sarah.connor@sky.net',
      firstName: 'Sarah',
      lastName: 'Connor',
      role: 'VIP Member',
    );

    testWidgets('renders user avatar, full name, email, and role badge',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authBloc.emit(const AuthAuthenticated(testUser));

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SC'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('sarah.connor@sky.net'), findsOneWidget);
      expect(find.text('VIP Member'), findsOneWidget);
    });

    testWidgets('triggers onNavigateToOrders when My Orders tile is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool navigatedToOrders = false;
      authBloc.emit(const AuthAuthenticated(testUser));

      await tester.pumpWidget(
        buildSubject(
          onNavigateToOrders: () => navigatedToOrders = true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('account_my_orders_tile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(navigatedToOrders, isTrue);
    });

    testWidgets('opens edit shipping address dialog and updates address',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authBloc.emit(const AuthAuthenticated(testUser));

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap address tile
      await tester.tap(find.byKey(const Key('account_shipping_address_tile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(AlertDialog, 'Edit Shipping Address'), findsOneWidget);
      expect(find.byKey(const Key('edit_address_street_field')), findsOneWidget);

      // Enter new street
      await tester.enterText(
        find.byKey(const Key('edit_address_street_field')),
        '100 Cyberdyne Blvd',
      );
      await tester.tap(find.byKey(const Key('edit_address_save_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Shipping address updated successfully'), findsOneWidget);
      expect(find.textContaining('100 Cyberdyne Blvd'), findsOneWidget);
    });

    testWidgets('opens change password dialog and validates input',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authBloc.emit(const AuthAuthenticated(testUser));

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('account_change_password_tile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(AlertDialog, 'Change Password'), findsOneWidget);

      // Enter too short password
      await tester.enterText(
        find.byKey(const Key('change_password_new_field')),
        '123',
      );
      await tester.tap(find.byKey(const Key('change_password_save_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Enter mismatched password
      await tester.enterText(
        find.byKey(const Key('change_password_new_field')),
        'Secr3tPassword!',
      );
      await tester.enterText(
        find.byKey(const Key('change_password_confirm_field')),
        'DifferentPass!',
      );
      await tester.tap(find.byKey(const Key('change_password_save_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Enter matching password
      await tester.enterText(
        find.byKey(const Key('change_password_confirm_field')),
        'Secr3tPassword!',
      );
      await tester.tap(find.byKey(const Key('change_password_save_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Password updated successfully'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog on sign out and dispatches logout',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      authBloc.emit(const AuthAuthenticated(testUser));

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Sign Out
      await tester.tap(find.byKey(const Key('account_sign_out_tile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(
          'Are you sure you want to sign out of your PrismCommerce account?',
        ),
        findsOneWidget,
      );

      // Tap confirm button
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('sign_out_confirm_button')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authBloc.state, isA<AuthUnauthenticated>());
    });
  });
}
