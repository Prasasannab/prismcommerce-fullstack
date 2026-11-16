import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cart/data/models/cart_item_model.dart';

void main() {
  group('CartItemModel', () {
    const testItem = CartItemModel(
      productId: 'p-1',
      variantId: 'v-1',
      productName: 'Prism Pulse Pods',
      variantTitle: 'Space Black',
      sku: 'PPP-BLK-PRO',
      price: 249.00,
      quantity: 2,
      imageUrl: 'https://example.com/pods.jpg',
      maxStock: 10,
    );

    test('calculates totalPrice and displayTitle correctly', () {
      expect(testItem.totalPrice, 498.00);
      expect(testItem.displayTitle, 'Prism Pulse Pods (Space Black)');
    });

    test('serializes and deserializes to/from JSON correctly', () {
      final json = testItem.toJson();
      final fromJson = CartItemModel.fromJson(json);

      expect(fromJson.productId, 'p-1');
      expect(fromJson.variantId, 'v-1');
      expect(fromJson.productName, 'Prism Pulse Pods');
      expect(fromJson.variantTitle, 'Space Black');
      expect(fromJson.sku, 'PPP-BLK-PRO');
      expect(fromJson.price, 249.00);
      expect(fromJson.quantity, 2);
      expect(fromJson.imageUrl, 'https://example.com/pods.jpg');
      expect(fromJson.maxStock, 10);
      expect(fromJson, equals(testItem));
    });

    test('handles fallback title in fromJson when productName missing', () {
      final rawJson = {
        'productId': 'p-2',
        'title': 'Legacy Product Name',
        'price': 99.0,
        'quantity': 1,
      };
      final item = CartItemModel.fromJson(rawJson);
      expect(item.productName, 'Legacy Product Name');
      expect(item.quantity, 1);
      expect(item.price, 99.0);
    });

    test('copyWith updates specified fields', () {
      final updated = testItem.copyWith(quantity: 5, price: 299.00);
      expect(updated.quantity, 5);
      expect(updated.price, 299.00);
      expect(updated.productId, testItem.productId);
      expect(updated.totalPrice, 1495.00);
    });
  });
}
