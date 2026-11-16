import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/catalog/data/models/category_model.dart';
import 'package:mobile/features/catalog/data/models/product_detail_model.dart';
import 'package:mobile/features/catalog/data/models/product_summary_model.dart';
import 'package:mobile/features/catalog/data/models/product_variant_model.dart';

void main() {
  group('CategoryModel', () {
    test('serializes and deserializes cleanly', () {
      final json = {
        'id': 'cat-1',
        'name': 'Audio',
        'slug': 'audio',
        'description': 'Headphones & audio',
        'imageUrl': 'https://example.com/audio.jpg',
      };

      final model = CategoryModel.fromJson(json);
      expect(model.id, 'cat-1');
      expect(model.name, 'Audio');
      expect(model.slug, 'audio');
      expect(model.description, 'Headphones & audio');
      expect(model.imageUrl, 'https://example.com/audio.jpg');

      final serialized = model.toJson();
      expect(serialized['id'], 'cat-1');
      expect(serialized['name'], 'Audio');
      expect(serialized['slug'], 'audio');
    });

    test('handles PascalCase from ASP.NET Core', () {
      final json = {
        'Id': 'cat-2',
        'Name': 'Laptops',
        'Slug': 'laptops',
        'Description': 'Laptops for pros',
        'ImageUrl': 'https://example.com/laptops.jpg',
      };

      final model = CategoryModel.fromJson(json);
      expect(model.id, 'cat-2');
      expect(model.name, 'Laptops');
      expect(model.slug, 'laptops');
    });
  });

  group('ProductVariantModel', () {
    test('deserializes and checks stock indicators', () {
      final json = {
        'id': 'var-1',
        'sku': 'PPP-BLK-PRO',
        'title': 'Space Black | Pro Edition',
        'color': 'Space Black',
        'size': 'Pro Edition',
        'priceAdjustment': 20.0,
        'finalPrice': 269.0,
        'availableStock': 3,
      };

      final variant = ProductVariantModel.fromJson(json);
      expect(variant.id, 'var-1');
      expect(variant.sku, 'PPP-BLK-PRO');
      expect(variant.priceAdjustment, 20.0);
      expect(variant.finalPrice, 269.0);
      expect(variant.availableStock, 3);
      expect(variant.isInStock, isTrue);
      expect(variant.isLowStock, isTrue);

      final outOfStock = ProductVariantModel.fromJson({
        'id': 'var-2',
        'sku': 'PPP-OUT',
        'title': 'Out Edition',
        'priceAdjustment': 0,
        'finalPrice': 100,
        'availableStock': 0,
      });
      expect(outOfStock.isInStock, isFalse);
      expect(outOfStock.isLowStock, isFalse);
    });
  });

  group('ProductSummaryModel', () {
    test('deserializes and provides formatted helpers', () {
      final json = {
        'id': 'prod-1',
        'name': 'Prism Pulse Pods',
        'slug': 'prism-pulse-pods',
        'description': 'Wireless earbuds with ANC',
        'basePrice': 249.00,
        'imageUrls': [
          'https://images.unsplash.com/photo-1590658268037-6bf12165a8df',
          'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb',
        ],
        'categoryName': 'Audio',
        'variantCount': 3,
        'rating': 4.9,
        'reviewCount': 142,
      };

      final model = ProductSummaryModel.fromJson(json);
      expect(model.id, 'prod-1');
      expect(model.name, 'Prism Pulse Pods');
      expect(model.basePrice, 249.00);
      expect(model.formattedPrice, '\$249.00');
      expect(model.primaryImageUrl,
          'https://images.unsplash.com/photo-1590658268037-6bf12165a8df');
      expect(model.categoryName, 'Audio');
      expect(model.variantCount, 3);

      final serialized = model.toJson();
      expect(serialized['id'], 'prod-1');
      expect(serialized['basePrice'], 249.00);
    });
  });

  group('ProductDetailModel', () {
    test('deserializes complex variant matrix and stock sums', () {
      final json = {
        'id': 'prod-detail-1',
        'name': 'PrismBook Pro 16',
        'slug': 'prismbook-pro-16',
        'description': 'Pro workstation laptop',
        'basePrice': 1999.00,
        'imageUrls': ['https://example.com/laptop.jpg'],
        'category': {
          'id': 'cat-laptops',
          'name': 'Laptops',
          'slug': 'laptops',
        },
        'variants': [
          {
            'id': 'var-1',
            'sku': 'PBP-16-32G',
            'title': '32GB Space Gray',
            'color': 'Space Gray',
            'size': '16-inch',
            'priceAdjustment': 0.0,
            'finalPrice': 1999.00,
            'availableStock': 10,
          },
          {
            'id': 'var-2',
            'sku': 'PBP-16-64G',
            'title': '64GB Silver',
            'color': 'Silver',
            'size': '16-inch',
            'priceAdjustment': 400.0,
            'finalPrice': 2399.00,
            'availableStock': 5,
          },
        ],
        'rating': 5.0,
        'reviewCount': 64,
      };

      final detail = ProductDetailModel.fromJson(json);
      expect(detail.id, 'prod-detail-1');
      expect(detail.category.name, 'Laptops');
      expect(detail.variants.length, 2);
      expect(detail.totalStock, 15);
      expect(detail.isInStock, isTrue);
      expect(detail.formattedPrice, '\$1999.00');
    });
  });
}
