import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/catalog/bloc/catalog_bloc.dart';
import 'package:mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:mobile/features/catalog/presentation/screens/catalog_screen.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_cat_');
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
      'CatalogScreen renders header, banner, categories, and handles quick-add',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = CatalogRepository(fallbackOnly: true);
    final bloc = CatalogBloc(catalogRepository: repository);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CatalogRepository>.value(value: repository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CatalogBloc>.value(
              value: bloc..add(const CatalogStarted()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const CatalogScreen(),
          ),
        ),
      ),
    );

    // Pump and let BLoC emit CatalogLoaded
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Brand title & Header
    expect(find.text('PrismCommerce'), findsOneWidget);
    expect(find.text('High-Concurrency Store'), findsOneWidget);

    // Verify Promotional Flash Drop Banner
    expect(find.text('Summer Tech Drop 2026'), findsOneWidget);
    expect(find.text('CODE: TECH'), findsWidgets);

    // Verify Category Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('Wearables'), findsOneWidget);

    // Verify Products Grid
    expect(find.text('Prism Pulse Pods'), findsOneWidget);
    expect(find.text('Apex Wireless'), findsOneWidget);
    expect(find.text('PrismBook Pro 16'), findsOneWidget);

    // Test Quick Add
    final quickAddPod = find.byKey(
      const Key('quick_add_11111111-1111-1111-1111-111111111111'),
    );
    expect(quickAddPod, findsOneWidget);
    await tester.tap(quickAddPod);
    await tester.pump(const Duration(milliseconds: 100));

    // Cart cache should hold the added item
    final cart = StorageService.instance.getCart();
    expect(cart.isNotEmpty, isTrue);
    expect(cart.first['productId'], '11111111-1111-1111-1111-111111111111');

    // Test Category Pill Filter (Tap 'Audio')
    final audioPill = find.byKey(const Key('category_pill_Audio'));
    expect(audioPill, findsOneWidget);
    await tester.tap(audioPill);
    await tester.pump(const Duration(milliseconds: 100));

    // In Audio collection: Prism Pulse Pods & Apex Wireless are present, PrismBook Pro is filtered out
    expect(find.text('Audio Collection'), findsOneWidget);
    expect(find.text('Prism Pulse Pods'), findsOneWidget);
    expect(find.text('Apex Wireless'), findsOneWidget);
    expect(find.text('PrismBook Pro 16'), findsNothing);

    // Reset Filter
    final resetBtn = find.text('Reset');
    expect(resetBtn, findsOneWidget);
    await tester.tap(resetBtn);
    await tester.pump(const Duration(milliseconds: 100));

    // All products restored
    expect(find.text('All Products'), findsOneWidget);
    expect(find.text('PrismBook Pro 16'), findsOneWidget);

    bloc.close();
  });
}
