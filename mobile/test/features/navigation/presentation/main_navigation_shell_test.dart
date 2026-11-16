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
import 'package:mobile/features/cart/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/data/repositories/cart_repository.dart';
import 'package:mobile/features/catalog/bloc/catalog_bloc.dart';
import 'package:mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:mobile/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:mobile/features/catalog/presentation/screens/explore_categories_screen.dart';
import 'package:mobile/features/navigation/presentation/screens/main_navigation_shell.dart';
import 'package:mobile/features/profile/presentation/screens/account_screen.dart';

class MockAuthRepository extends AuthRepository {
  @override
  Future<UserModel?> checkAuthStatus() async => null;
}

void main() {
  late CatalogRepository catalogRepository;
  late CartRepository cartRepository;
  late AuthRepository authRepository;
  late ThemeCubit themeCubit;
  late AuthBloc authBloc;
  late CatalogBloc catalogBloc;
  late CartBloc cartBloc;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp('hive_test_nav_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>('${StorageService.settingsBoxName}_nav');
    final cartBox =
        await Hive.openBox<dynamic>('${StorageService.cartBoxName}_nav');
    StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  setUp(() {
    catalogRepository = CatalogRepository(fallbackOnly: true);
    cartRepository = CartRepository();
    authRepository = MockAuthRepository();
    themeCubit = ThemeCubit(storageService: StorageService.instance);
    authBloc = AuthBloc(authRepository: authRepository);
    catalogBloc = CatalogBloc(catalogRepository: catalogRepository);
    cartBloc = CartBloc(cartRepository: cartRepository);
  });

  tearDown(() {
    themeCubit.close();
    authBloc.close();
    catalogBloc.close();
    cartBloc.close();
  });

  Widget buildSubject({int initialIndex = 0}) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogRepository>.value(value: catalogRepository),
        RepositoryProvider<CartRepository>.value(value: cartRepository),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<CatalogBloc>.value(
            value: catalogBloc..add(const CatalogStarted()),
          ),
          BlocProvider<CartBloc>.value(
            value: cartBloc..add(const CartStarted()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: MainNavigationShell(initialIndex: initialIndex),
        ),
      ),
    );
  }

  group('MainNavigationShell', () {
    testWidgets('renders all 4 tabs and starts at initial Shop tab',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigation tabs exist
      expect(find.byKey(const Key('nav_tab_shop')), findsOneWidget);
      expect(find.byKey(const Key('nav_tab_explore')), findsOneWidget);
      expect(find.byKey(const Key('nav_tab_orders')), findsOneWidget);
      expect(find.byKey(const Key('nav_tab_account')), findsOneWidget);

      // Verify IndexedStack is present and index is 0
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);
      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 0);

      // Shop screen content is visible
      expect(find.byKey(const Key('theme_toggle_button')), findsOneWidget);
      expect(find.byType(CatalogScreen), findsOneWidget);
    });

    testWidgets('switches to Explore tab when Explore is selected',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Explore tab
      await tester.tap(find.byKey(const Key('nav_tab_explore')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);
      expect(find.byType(ExploreCategoriesScreen), findsOneWidget);
    });

    testWidgets('switches to My Orders tab when My Orders is selected',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap My Orders tab
      await tester.tap(find.byKey(const Key('nav_tab_orders')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 2);
      expect(find.widgetWithText(AppBar, 'My Orders'), findsOneWidget);
    });

    testWidgets('switches to Account tab when Account is selected',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Account tab
      await tester.tap(find.byKey(const Key('nav_tab_account')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 3);
      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('supports programmatic switching from child screens',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Start at Account tab (index 3)
      await tester.pumpWidget(buildSubject(initialIndex: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final shellState = tester.state<MainNavigationShellState>(
        find.byType(MainNavigationShell),
      );
      expect(shellState.currentIndex, 3);

      // Programmatically switch to Shop tab
      shellState.switchToTab(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(shellState.currentIndex, 0);
      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 0);
    });
  });
}
