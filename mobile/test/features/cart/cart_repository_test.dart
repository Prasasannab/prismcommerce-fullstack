import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/features/cart/data/models/cart_item_model.dart';
import 'package:mobile/features/cart/data/repositories/cart_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late CartRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cart_repo_test_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>('${StorageService.settingsBoxName}_test');
    final cartBox =
        await Hive.openBox<dynamic>('${StorageService.cartBoxName}_test');

    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
    repository = CartRepository(storageService: storageService);
  });

  group('CartRepository', () {
    test('loadCart returns empty list initially', () async {
      final items = await repository.loadCart();
      expect(items, isEmpty);
    });

    test('saveCart persists items and loadCart retrieves them', () async {
      const items = [
        CartItemModel(
          productId: 'p-1',
          variantId: 'v-1',
          productName: 'Apex Wireless',
          variantTitle: 'Studio Black',
          sku: 'APX-BLK',
          price: 389.00,
          quantity: 2,
          imageUrl: 'https://example.com/apex.jpg',
        ),
      ];

      await repository.saveCart(items);
      final loaded = await repository.loadCart();

      expect(loaded.length, 1);
      expect(loaded.first.productName, 'Apex Wireless');
      expect(loaded.first.quantity, 2);
      expect(loaded.first.totalPrice, 778.00);
    });

    test('clearCart empties persisted items', () async {
      const items = [
        CartItemModel(
          productId: 'p-1',
          variantId: 'v-1',
          productName: 'Apex Wireless',
          variantTitle: 'Studio Black',
          sku: 'APX-BLK',
          price: 389.00,
          quantity: 1,
          imageUrl: '',
        ),
      ];

      await repository.saveCart(items);
      expect((await repository.loadCart()).length, 1);

      await repository.clearCart();
      expect((await repository.loadCart()), isEmpty);
    });
  });
}
