import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/cart/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/data/models/cart_item_model.dart';
import 'package:mobile/features/cart/data/repositories/cart_repository.dart';
import 'package:mobile/features/cart/presentation/widgets/cart_sheet.dart';
import 'package:mobile/features/checkout/data/models/order_response_model.dart';
import 'package:mobile/features/checkout/data/repositories/checkout_repository.dart';
import 'package:mobile/features/checkout/presentation/widgets/order_confirmation_dialog.dart';
import 'package:mobile/features/orders/presentation/screens/order_detail_screen.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late CartRepository cartRepository;
  late CheckoutRepository checkoutRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cart_sheet_test_');
    Hive.init(tempDir.path);
    final settingsBox = await Hive.openBox<dynamic>(
        '${StorageService.settingsBoxName}_cart_sheet');
    final cartBox =
        await Hive.openBox<dynamic>('${StorageService.cartBoxName}_cart_sheet');

    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
    cartRepository = CartRepository(storageService: storageService);
    checkoutRepository = CheckoutRepository(
      storageService: storageService,
      fallbackOnly: true,
    );
  });

  group('CartSheet & OrderConfirmationDialog', () {
    testWidgets('renders empty cart view when no items exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bloc = CartBloc(cartRepository: cartRepository);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BlocProvider<CartBloc>.value(
            value: bloc,
            child: Scaffold(
              body: CartSheet(checkoutRepository: checkoutRepository),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Shopping Bag (0)'), findsOneWidget);
      expect(find.text('Your Shopping Bag is Empty'), findsOneWidget);
      expect(find.byKey(const Key('start_shopping_button')), findsOneWidget);

      bloc.close();
    });

    testWidgets(
        'renders items, promo section, order summary, and handles promo code entry',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bloc = CartBloc(cartRepository: cartRepository);

      await tester.runAsync(() async {
        bloc.add(
          const CartItemAdded(
            CartItemModel(
              productId: 'prod-pod',
              variantId: 'var-blk',
              productName: 'Prism Pulse Pods',
              variantTitle: 'Space Black',
              sku: 'PPP-BLK-PRO',
              price: 249.00,
              quantity: 1,
              imageUrl: '',
              maxStock: 10,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BlocProvider<CartBloc>.value(
            value: bloc,
            child: Scaffold(
              body: CartSheet(checkoutRepository: checkoutRepository),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header & item title
      expect(find.text('Shopping Bag (1)'), findsOneWidget);
      expect(find.text('Prism Pulse Pods'), findsOneWidget);
      expect(find.text('Space Black'), findsOneWidget);

      // Verify subtotal ($249.00) and free shipping
      expect(find.byKey(const Key('cart_subtotal_text')), findsOneWidget);
      expect(find.text('\$249.00'), findsWidgets);
      expect(find.text('FREE'), findsOneWidget);

      // Enter Promo Code 'TECH'
      final promoField = find.byKey(const Key('promo_input_field'));
      expect(promoField, findsOneWidget);
      await tester.enterText(promoField, 'TECH');
      await tester.pump();

      final applyBtn = find.byKey(const Key('apply_promo_button'));
      expect(applyBtn, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(applyBtn);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify promo badge and discount summary
      expect(find.byKey(const Key('applied_promo_badge')), findsOneWidget);
      expect(find.text('TECH applied (20% OFF)'), findsOneWidget);
      expect(find.byKey(const Key('cart_discount_text')), findsOneWidget);

      // Verify updated total ($249 - 20% = $199.20)
      expect(find.text('\$199.20'), findsWidgets);

      bloc.close();
    });

    testWidgets('OrderConfirmationDialog renders order summary and dismisses',
        (tester) async {
      final mockOrder = OrderResponseModel(
        id: 'mock-order-id-123',
        orderNumber: 'ORD-2026-9999',
        userId: 'mock-user-id',
        status: 'Pending',
        paymentStatus: 'Authorized',
        totalAmount: 199.20,
        shippingAddress: '123 Market St, San Francisco, CA',
        createdAt: DateTime.now(),
        items: const [],
      );

      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  OrderConfirmationDialog.show(
                    context,
                    order: mockOrder,
                    onContinueShopping: () {
                      continued = true;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      // Verify celebration checkmark & details
      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.text('ORD-2026-9999'), findsOneWidget);
      expect(find.text('\$199.20'), findsOneWidget);
      expect(find.text('AUTHORIZED'), findsOneWidget);
      expect(find.text('123 Market St, San Francisco, CA'), findsOneWidget);

      // Tap Continue Shopping
      final continueBtn =
          find.byKey(const Key('order_continue_shopping_button'));
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(continued, isTrue);
      expect(find.text('Order Placed Successfully!'), findsNothing);
    });

    testWidgets(
        'OrderConfirmationDialog tapping Track Order navigates to OrderDetailScreen',
        (tester) async {
      final mockOrder = OrderResponseModel(
        id: 'mock-order-id-456',
        orderNumber: 'ORD-2026-TRACK',
        userId: 'mock-user-id',
        status: 'Paid',
        paymentStatus: 'Succeeded',
        totalAmount: 299.00,
        shippingAddress: '456 Tech Ave, San Francisco, CA',
        createdAt: DateTime.now(),
        items: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  OrderConfirmationDialog.show(
                    context,
                    order: mockOrder,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      final trackBtn = find.byKey(const Key('order_track_order_button'));
      expect(trackBtn, findsOneWidget);
      await tester.tap(trackBtn);
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.text('ORD-2026-TRACK'), findsWidgets);
    });
  });
}
