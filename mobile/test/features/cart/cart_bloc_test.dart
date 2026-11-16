import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/features/cart/bloc/cart_bloc.dart';
import 'package:mobile/features/cart/data/models/cart_item_model.dart';
import 'package:mobile/features/cart/data/repositories/cart_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late CartRepository repository;
  late CartBloc bloc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cart_bloc_test_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>('${StorageService.settingsBoxName}_bloc');
    final cartBox =
        await Hive.openBox<dynamic>('${StorageService.cartBoxName}_bloc');

    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
    repository = CartRepository(storageService: storageService);
    bloc = CartBloc(cartRepository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('CartBloc', () {
    const itemA = CartItemModel(
      productId: 'prod-1',
      variantId: 'var-1',
      productName: 'Prism Pulse Pods',
      variantTitle: 'Space Black',
      sku: 'PPP-BLK-PRO',
      price: 249.00,
      quantity: 1,
      imageUrl: 'https://example.com/pod.png',
      maxStock: 5,
    );

    const smallItem = CartItemModel(
      productId: 'prod-acc',
      variantId: 'var-acc',
      productName: 'Prism Braided Cable',
      variantTitle: 'Midnight',
      sku: 'PRM-CBL-MNT',
      price: 25.00,
      quantity: 1,
      imageUrl: 'https://example.com/cable.png',
      maxStock: 20,
    );

    test('initial state is empty with zero calculations', () {
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.subtotal, 0.0);
      expect(bloc.state.promoDiscount, 0.0);
      expect(bloc.state.shipping, 0.0);
      expect(bloc.state.total, 0.0);
      expect(bloc.state.totalItemCount, 0);
      expect(bloc.state.isPromoApplied, isFalse);
    });

    test('CartItemAdded adds new item and persists to repository', () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      expect(bloc.state.items.length, 1);
      expect(bloc.state.totalItemCount, 1);
      expect(bloc.state.subtotal, 249.00);
      expect(bloc.state.shipping, 0.0); // > 100 qualifies for free shipping
      expect(bloc.state.total, 249.00);

      final persisted = await repository.loadCart();
      expect(persisted.length, 1);
      expect(persisted.first.productId, 'prod-1');
    });

    test('CartItemAdded increments quantity if same product & variant exists',
        () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      expect(bloc.state.items.length, 1);
      expect(bloc.state.totalItemCount, 2);
      expect(bloc.state.subtotal, 498.00);
      expect(bloc.state.items.first.quantity, 2);
    });

    test('CartItemQuantityUpdated updates quantity and clamps to maxStock',
        () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      bloc.add(const CartItemQuantityUpdated(
        productId: 'prod-1',
        variantId: 'var-1',
        quantity: 10, // maxStock is 5
      ));
      await bloc.stream.first;

      expect(bloc.state.items.first.quantity, 5);
      expect(bloc.state.subtotal, 1245.00);
    });

    test('CartItemQuantityUpdated with 0 removes item', () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      bloc.add(const CartItemQuantityUpdated(
        productId: 'prod-1',
        variantId: 'var-1',
        quantity: 0,
      ));
      await bloc.stream.first;

      expect(bloc.state.items, isEmpty);
    });

    test('CartItemRemoved removes item completely', () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      bloc.add(const CartItemRemoved(
        productId: 'prod-1',
        variantId: 'var-1',
      ));
      await bloc.stream.first;

      expect(bloc.state.items, isEmpty);
    });

    test(
        r'Shipping is $15 when subtotal <= $100, and $0 when subtotal > $100',
        () async {
      // 1 small item ($25)
      bloc.add(const CartItemAdded(smallItem));
      await bloc.stream.first;

      expect(bloc.state.subtotal, 25.00);
      expect(bloc.state.shipping, 15.00);
      expect(bloc.state.total, 40.00);

      // Add expensive item ($249) -> total subtotal $274 > 100
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      expect(bloc.state.subtotal, 274.00);
      expect(bloc.state.shipping, 0.00);
      expect(bloc.state.total, 274.00);
    });

    test('CartPromoCodeApplied applies "TECH" giving 20% discount', () async {
      bloc.add(const CartItemAdded(itemA)); // 249.00
      await bloc.stream.first;

      bloc.add(const CartPromoCodeApplied('TECH'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isPromoApplied, isTrue);
      expect(bloc.state.promoCode, 'TECH');
      final expectedDiscount = 249.00 * 0.20;
      expect((bloc.state.promoDiscount - expectedDiscount).abs() < 0.001, isTrue);
      expect((bloc.state.total - 199.20).abs() < 0.001, isTrue);
    });

    test('CartPromoCodeApplied rejects invalid codes with promoError',
        () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      bloc.add(const CartPromoCodeApplied('INVALID_CODE'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isPromoApplied, isFalse);
      expect(bloc.state.promoError, isNotNull);
      expect(bloc.state.promoDiscount, 0.0);
    });

    test('CartPromoCodeRemoved clears applied promo discount', () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      bloc.add(const CartPromoCodeApplied('tech')); // case-insensitive
      await Future<void>.delayed(Duration.zero);

      bloc.add(const CartPromoCodeRemoved());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isPromoApplied, isFalse);
      expect(bloc.state.promoCode, isNull);
      expect(bloc.state.promoDiscount, 0.0);
      expect(bloc.state.total, 249.00);
    });

    test('CartCleared resets items, calculations, and local cache', () async {
      bloc.add(const CartItemAdded(itemA));
      await bloc.stream.first;

      bloc.add(const CartPromoCodeApplied('TECH'));
      await bloc.stream.first;

      bloc.add(const CartCleared());
      await bloc.stream.first;

      expect(bloc.state.items, isEmpty);
      expect(bloc.state.subtotal, 0.0);
      expect(bloc.state.isPromoApplied, isFalse);

      final persisted = await repository.loadCart();
      expect(persisted, isEmpty);
    });
  });
}
