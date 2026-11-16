import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/checkout/data/models/order_response_model.dart';
import 'package:mobile/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:mobile/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:mobile/features/orders/presentation/widgets/order_tracking_timeline.dart';

void main() {
  final testOrder = OrderResponseModel(
    id: 'ord-unit-test-1',
    orderNumber: 'ORD-20261113-C81E2E47',
    userId: 'usr-1',
    status: 'Delivered',
    paymentStatus: 'Succeeded',
    totalAmount: 249.00,
    shippingAddress: '742 Evergreen Terrace, Springfield, OR 97477',
    stripePaymentIntentId: 'pi_3MtwBwLkdIwHu7ix28a3tqPa',
    createdAt: DateTime(2026, 11, 13, 15, 30),
    items: const [
      OrderItemResponseModel(
        id: 'item-1',
        productVariantId: 'var-1',
        productName: 'Prism Pulse Pods',
        variantTitle: 'Space Black / Active Noise Cancelling',
        sku: 'PRM-POD-BLK',
        unitPrice: 249.00,
        quantity: 1,
        totalPrice: 249.00,
      ),
    ],
  );

  final cancelledOrder = OrderResponseModel(
    id: 'ord-unit-test-2',
    orderNumber: 'ORD-20261110-B90F2156',
    userId: 'usr-1',
    status: 'Cancelled',
    paymentStatus: 'Refunded',
    totalAmount: 129.00,
    shippingAddress: '123 Market St, San Francisco, CA 94103',
    stripePaymentIntentId: 'pi_3PwsEyOngLyKx0la51d6wtSd',
    createdAt: DateTime(2026, 11, 10, 10, 0),
    items: const [
      OrderItemResponseModel(
        id: 'item-2',
        productVariantId: 'var-2',
        productName: 'Prism MagSafe Stand',
        variantTitle: 'Anodized Black',
        sku: 'PRM-MAG-BLK',
        unitPrice: 129.00,
        quantity: 1,
        totalPrice: 129.00,
      ),
    ],
  );

  Widget createTestWidget(OrderResponseModel order) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: OrderDetailScreen(order: order),
    );
  }

  testWidgets('OrderDetailScreen renders complete fulfillment details and timeline',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget(testOrder));
    await tester.pumpAndSettle();

    // Verify AppBar & Status
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.byKey(const Key('order_detail_order_number')), findsOneWidget);
    expect(find.text('ORD-20261113-C81E2E47'), findsWidgets);
    expect(find.byType(OrderStatusBadge), findsWidgets);

    // Verify Section 1: Timeline
    expect(find.byType(OrderTrackingTimeline), findsOneWidget);
    expect(find.text('Live Fulfillment Status'), findsOneWidget);
    expect(find.text('Order Placed'), findsOneWidget);
    expect(find.text('Payment Confirmed'), findsOneWidget);
    expect(find.text('Processing & Packed'), findsOneWidget);
    expect(find.text('Shipped & Delivered'), findsOneWidget);

    // Verify Section 2: Items Card
    expect(find.text('Items in this Order'), findsOneWidget);
    expect(find.text('Prism Pulse Pods'), findsOneWidget);
    expect(find.text('Space Black / Active Noise Cancelling'), findsOneWidget);
    expect(find.text('SKU: PRM-POD-BLK'), findsOneWidget);
    expect(find.text('Qty: 1'), findsOneWidget);

    // Verify Section 3: Shipping
    expect(find.text('Shipping Destination'), findsOneWidget);
    expect(find.text('742 Evergreen Terrace, Springfield, OR 97477'), findsOneWidget);
    expect(find.text('Insured Express Dispatch'), findsOneWidget);

    // Verify Section 4: Payment Summary
    expect(find.text('Payment Summary'), findsOneWidget);
    expect(find.text('Total Paid'), findsOneWidget);
    expect(find.text('\$249.00'), findsWidgets);
    expect(find.text('pi_3MtwBwLkdIwHu7ix28a3tqPa'), findsOneWidget);

    // Verify "Need Help?" Action
    final helpBtn = find.byKey(const Key('order_detail_need_help_button'));
    expect(helpBtn, findsOneWidget);
    await tester.tap(helpBtn);
    await tester.pumpAndSettle();

    expect(find.text('PrismCommerce Concierge'), findsOneWidget);
    expect(find.text('support@prismcommerce.com'), findsOneWidget);

    // Close help modal
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('PrismCommerce Concierge'), findsNothing);
  });

  testWidgets('OrderDetailScreen handles cancelled order state cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget(cancelledOrder));
    await tester.pumpAndSettle();

    expect(find.text('Order Cancelled'), findsOneWidget);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.text('REFUNDED'), findsOneWidget);
    expect(find.text('Prism MagSafe Stand'), findsOneWidget);
  });
}
