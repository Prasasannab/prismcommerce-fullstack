import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/catalog/data/models/product_summary_model.dart';
import 'package:mobile/features/catalog/presentation/widgets/category_selector.dart';
import 'package:mobile/features/catalog/presentation/widgets/product_card.dart';
import 'package:mobile/features/catalog/presentation/widgets/product_shimmer_grid.dart';
import 'package:mobile/features/catalog/presentation/widgets/promo_banner.dart';

void main() {
  const sampleProduct = ProductSummaryModel(
    id: 'test-prod-1',
    name: 'Prism Pulse Pods',
    slug: 'prism-pulse-pods',
    description: 'Wireless earbuds with ANC',
    basePrice: 249.00,
    imageUrls: ['https://example.com/pods.jpg'],
    categoryName: 'Audio',
    variantCount: 3,
    rating: 4.9,
    reviewCount: 142,
  );

  group('Catalog UI Components', () {
    testWidgets('PromoBanner renders flash drop headline and coupon code',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: PromoBanner(),
          ),
        ),
      );

      expect(find.text('Summer Tech Drop 2026'), findsOneWidget);
      expect(find.text('LIMITED FLASH DROP'), findsOneWidget);
      expect(find.text('CODE: TECH'), findsOneWidget);
      expect(find.text('Claim 20% OFF'), findsOneWidget);
    });

    testWidgets('CategorySelector displays filter pills and triggers selection',
        (tester) async {
      String selected = 'All';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CategorySelector(
              selectedCategory: selected,
              onCategorySelected: (cat) => selected = cat,
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Laptops'), findsOneWidget);
      expect(find.text('Wearables'), findsOneWidget);

      await tester.tap(find.text('Audio'));
      await tester.pump();
      expect(selected, 'Audio');
    });

    testWidgets(
        'ProductCard contains Hero with correct tag, price tag, and quick add button',
        (tester) async {
      bool tapped = false;
      bool quickAdded = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 250,
              child: ProductCard(
                product: sampleProduct,
                onTap: () => tapped = true,
                onQuickAdd: () => quickAdded = true,
              ),
            ),
          ),
        ),
      );

      // Verify Hero animation tag format
      final heroFinder = find.byType(Hero);
      expect(heroFinder, findsOneWidget);
      final heroWidget = tester.widget<Hero>(heroFinder);
      expect(heroWidget.tag, 'product_image_${sampleProduct.id}');

      // Verify Product Info
      expect(find.text('Prism Pulse Pods'), findsOneWidget);
      expect(find.text('\$249.00'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('AUDIO'), findsOneWidget);

      // Verify Quick Add Button
      final quickAddBtn = find.byKey(Key('quick_add_${sampleProduct.id}'));
      expect(quickAddBtn, findsOneWidget);
      await tester.tap(quickAddBtn);
      expect(quickAdded, isTrue);

      // Verify Card Tap
      await tester.tap(find.text('Prism Pulse Pods'));
      expect(tapped, isTrue);
    });

    testWidgets('ProductShimmerGrid renders skeleton placeholders',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ProductShimmerGrid(itemCount: 4),
            ),
          ),
        ),
      );

      expect(find.byType(ProductShimmerGrid), findsOneWidget);
    });
  });
}
