import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/catalog/data/repositories/catalog_repository.dart';

void main() {
  late CatalogRepository repository;

  setUp(() {
    repository = CatalogRepository(fallbackOnly: true);
  });

  group('CatalogRepository', () {
    test('getCategories returns pre-configured categories', () async {
      final categories = await repository.getCategories();
      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.name == 'Audio'), isTrue);
      expect(categories.any((c) => c.name == 'Laptops'), isTrue);
      expect(categories.any((c) => c.name == 'Wearables'), isTrue);
    });

    test('getProducts returns seed items when offline', () async {
      final products = await repository.getProducts();
      expect(products, isNotEmpty);
      expect(products.length, greaterThanOrEqualTo(3));
      expect(products.any((p) => p.name.contains('Prism Pulse Pods')), isTrue);
    });

    test('getProducts filters by category', () async {
      final audioProducts = await repository.getProducts(categoryId: 'Audio');
      expect(audioProducts, isNotEmpty);
      expect(audioProducts.every((p) => p.categoryName == 'Audio'), isTrue);

      final laptopProducts =
          await repository.getProducts(categoryId: 'Laptops');
      expect(laptopProducts, isNotEmpty);
      expect(laptopProducts.every((p) => p.categoryName == 'Laptops'), isTrue);
    });

    test('getProducts filters by search term', () async {
      final results = await repository.getProducts(searchTerm: 'Apex');
      expect(results.length, 1);
      expect(results.first.name, 'Apex Wireless');
    });

    test('getProductById retrieves exact seed item', () async {
      final product = await repository
          .getProductById('11111111-1111-1111-1111-111111111111');
      expect(product.name, 'Prism Pulse Pods');
      expect(product.variants.length, 3);
      expect(product.variants.first.sku, 'PPP-BLK-PRO');
    });
  });
}
