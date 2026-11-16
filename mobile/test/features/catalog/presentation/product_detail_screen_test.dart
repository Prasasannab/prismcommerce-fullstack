import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:mobile/features/catalog/presentation/screens/product_detail_screen.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>(StorageService.settingsBoxName);
    final cartBox = await Hive.openBox<dynamic>(StorageService.cartBoxName);
    StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  testWidgets(
      'ProductDetailScreen renders Hero, variants, live SKU, and stepper',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = CatalogRepository(fallbackOnly: true);
    const testId = '11111111-1111-1111-1111-111111111111';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ProductDetailScreen(
          productId: testId,
          catalogRepository: repository,
        ),
      ),
    );

    // Initial pump & advance past async future
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & Hero
    expect(find.text('Prism Pulse Pods'), findsWidgets);
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'product_image_$testId');

    // Verify initial variant SKU
    expect(find.text('SKU: PPP-BLK-PRO'), findsOneWidget);
    expect(find.text('50 in stock'), findsOneWidget);

    // Switch to another variant chip (Polar White)
    final polarWhiteChip = find.byKey(const Key('variant_chip_PPP-WHT-PRO'));
    expect(polarWhiteChip, findsOneWidget);
    await tester.ensureVisible(polarWhiteChip);
    await tester.tap(polarWhiteChip);
    await tester.pump(const Duration(milliseconds: 50));

    // Verify dynamic update of SKU and Stock
    expect(find.text('SKU: PPP-WHT-PRO'), findsOneWidget);
    expect(find.text('40 in stock'), findsOneWidget);

    // Test Quantity Stepper
    expect(find.text('1'), findsWidgets);
    final plusBtn = find.byIcon(Icons.add);
    expect(plusBtn, findsOneWidget);
    await tester.ensureVisible(plusBtn);
    await tester.tap(plusBtn);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('quantity_value_text')), findsOneWidget);
    expect(find.text('2'), findsWidgets);

    // Verify sticky Bottom Add to Bag button
    final addToBagBtn = find.byKey(const Key('add_to_bag_button'));
    expect(addToBagBtn, findsOneWidget);
    expect(find.text('Add to Bag'), findsOneWidget);

    // Tap Add to Bag and verify storage cart update
    await tester.tap(addToBagBtn);
    await tester.pump(const Duration(milliseconds: 50));

    final cart = StorageService.instance.getCart();
    expect(cart.isNotEmpty, isTrue);
    expect(cart.first['productId'], testId);
  });
}
