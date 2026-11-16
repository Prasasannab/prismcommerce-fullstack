import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/orders/bloc/orders_bloc.dart';
import 'package:mobile/features/orders/data/repositories/orders_repository.dart';
import 'package:mobile/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:mobile/features/orders/presentation/screens/orders_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  final UserModel? initialUser;
  _FakeAuthRepository({this.initialUser});

  @override
  Future<UserModel?> checkAuthStatus() async => initialUser;
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_orders_screen_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>('${StorageService.settingsBoxName}_orders_screen');
    final cartBox =
        await Hive.openBox<dynamic>('${StorageService.cartBoxName}_orders_screen');
    StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  const demoUser = UserModel(
    id: 'usr-1',
    email: 'sarah.connor@prismcommerce.com',
    firstName: 'Sarah',
    lastName: 'Connor',
    role: 'Customer',
  );

  Widget createTestWidget({
    required AuthBloc authBloc,
    required OrdersBloc ordersBloc,
    VoidCallback? onNavigateToShop,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<OrdersBloc>.value(value: ordersBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: OrdersScreen(onNavigateToShop: onNavigateToShop),
      ),
    );
  }

  testWidgets('OrdersScreen displays guest prompt when unauthenticated',
      (tester) async {
    final authRepo = _FakeAuthRepository(initialUser: null);
    final authBloc = AuthBloc(authRepository: authRepo);
    final ordersRepo = OrdersRepository(fallbackOnly: true);
    final ordersBloc = OrdersBloc(ordersRepository: ordersRepo);

    await tester.pumpWidget(
      createTestWidget(authBloc: authBloc, ordersBloc: ordersBloc),
    );
    await tester.pumpAndSettle();

    expect(find.text('Track Your Orders'), findsOneWidget);
    expect(find.byKey(const Key('orders_sign_in_button')), findsOneWidget);

    authBloc.close();
    ordersBloc.close();
  });

  testWidgets(
      'OrdersScreen renders filters, order cards, and handles filter chips when authenticated',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authRepo = _FakeAuthRepository(initialUser: demoUser);
    final authBloc = AuthBloc(authRepository: authRepo);
    authBloc.emit(const AuthAuthenticated(demoUser));

    final ordersRepo = OrdersRepository(fallbackOnly: true);
    final ordersBloc = OrdersBloc(ordersRepository: ordersRepo)
      ..add(const OrdersStarted());

    await tester.pumpWidget(
      createTestWidget(authBloc: authBloc, ordersBloc: ordersBloc),
    );
    await tester.pumpAndSettle();

    // Verify Title & Filter Bar
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.byKey(const Key('order_filter_all')), findsOneWidget);
    expect(find.byKey(const Key('order_filter_active')), findsOneWidget);
    expect(find.byKey(const Key('order_filter_delivered')), findsOneWidget);
    expect(find.byKey(const Key('order_filter_cancelled')), findsOneWidget);

    // Verify Order cards in All view
    expect(find.text('ORD-20261113-C81E2E47'), findsOneWidget);
    expect(find.text('ORD-20261114-A59B1102'), findsOneWidget);

    // Tap 'Delivered' filter chip
    await tester.tap(find.byKey(const Key('order_filter_delivered')));
    await tester.pumpAndSettle();

    // Only delivered order shown
    expect(find.text('ORD-20261113-C81E2E47'), findsOneWidget);
    expect(find.text('ORD-20261114-A59B1102'), findsNothing);

    // Tap order card to open OrderDetailScreen
    await tester.tap(find.text('ORD-20261113-C81E2E47'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('ORD-20261113-C81E2E47'), findsWidgets);

    authBloc.close();
    ordersBloc.close();
  });

  testWidgets(
      'OrdersScreen shows empty state and triggers onNavigateToShop when empty',
      (tester) async {
    bool navigatedToShop = false;
    final authRepo = _FakeAuthRepository(initialUser: demoUser);
    final authBloc = AuthBloc(authRepository: authRepo);
    authBloc.emit(const AuthAuthenticated(demoUser));

    final ordersRepo = OrdersRepository(fallbackOnly: true);
    final ordersBloc = OrdersBloc(ordersRepository: ordersRepo);
    ordersBloc.emit(const OrdersLoaded(
      orders: [],
      filteredOrders: [],
      selectedStatus: null,
    ));

    await tester.pumpWidget(
      createTestWidget(
        authBloc: authBloc,
        ordersBloc: ordersBloc,
        onNavigateToShop: () => navigatedToShop = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Orders Yet'), findsOneWidget);
    final startShopBtn = find.byKey(const Key('orders_start_shopping_button'));
    expect(startShopBtn, findsOneWidget);

    await tester.tap(startShopBtn);
    await tester.pumpAndSettle();

    expect(navigatedToShop, isTrue);

    authBloc.close();
    ordersBloc.close();
  });
}
