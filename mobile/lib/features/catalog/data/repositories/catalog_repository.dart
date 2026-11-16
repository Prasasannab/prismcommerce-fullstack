import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_detail_model.dart';
import '../models/product_summary_model.dart';
import '../models/product_variant_model.dart';

/// Repository handling product catalog retrieval from the ASP.NET Core 8 API
/// with robust fallback caching and seed mock support for offline resilience.
class CatalogRepository {
  final ApiClient _apiClient;
  final bool fallbackOnly;

  CatalogRepository({
    ApiClient? apiClient,
    this.fallbackOnly = false,
  }) : _apiClient = apiClient ?? ApiClient();

  /// Default categories matching backend database seeds.
  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Audio',
      slug: 'audio',
      description: 'High-fidelity headphones, earbuds, and premium audio equipment.',
      imageUrl: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b',
      productCount: 24,
    ),
    CategoryModel(
      id: '00000000-0000-0000-0000-000000000002',
      name: 'Laptops',
      slug: 'laptops',
      description: 'High-performance laptops and workstations for creators and developers.',
      imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
      productCount: 18,
    ),
    CategoryModel(
      id: '00000000-0000-0000-0000-000000000003',
      name: 'Wearables',
      slug: 'wearables',
      description: 'Smartwatches, fitness bands, and wearable devices.',
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
      productCount: 15,
    ),
  ];

  /// Rich seed catalog data aligning with backend EF Core DbInitializer.
  static final List<ProductDetailModel> seedProductDetails = [
    ProductDetailModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Prism Pulse Pods',
      slug: 'prism-pulse-pods',
      description:
          'Next-generation wireless earbuds featuring adaptive active noise cancellation, custom high-excursion driver, and spatial audio with dynamic head tracking.',
      basePrice: 249.00,
      imageUrls: const [
        'https://images.unsplash.com/photo-1590658268037-6bf12165a8df',
        'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb',
      ],
      category: defaultCategories[0],
      variants: const [
        ProductVariantModel(
          id: '11111111-1111-1111-1111-11111111111a',
          sku: 'PPP-BLK-PRO',
          title: 'Space Black | Pro Edition',
          color: 'Space Black',
          size: 'Pro Edition',
          priceAdjustment: 0.0,
          finalPrice: 249.00,
          availableStock: 50,
        ),
        ProductVariantModel(
          id: '11111111-1111-1111-1111-11111111111b',
          sku: 'PPP-WHT-PRO',
          title: 'Polar White | Pro Edition',
          color: 'Polar White',
          size: 'Pro Edition',
          priceAdjustment: 0.0,
          finalPrice: 249.00,
          availableStock: 40,
        ),
        ProductVariantModel(
          id: '11111111-1111-1111-1111-11111111111c',
          sku: 'PPP-BLU-PRO',
          title: 'Midnight Blue | Pro Edition',
          color: 'Midnight Blue',
          size: 'Pro Edition',
          priceAdjustment: 20.0,
          finalPrice: 269.00,
          availableStock: 12,
        ),
      ],
      rating: 4.9,
      reviewCount: 142,
    ),
    ProductDetailModel(
      id: '22222222-2222-2222-2222-222222222222',
      name: 'Apex Wireless',
      slug: 'apex-wireless',
      description:
          'Studio noise-cancelling over-ear headphones with custom 40mm beryllium drivers, lossless audio support, and 40-hour ultra-long battery life.',
      basePrice: 389.00,
      imageUrls: const [
        'https://images.unsplash.com/photo-1546435770-a3e426bf472b',
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
      ],
      category: defaultCategories[0],
      variants: const [
        ProductVariantModel(
          id: '22222222-2222-2222-2222-22222222222a',
          sku: 'APX-BLK-STU',
          title: 'Studio Black',
          color: 'Studio Black',
          size: 'Over-Ear',
          priceAdjustment: 0.0,
          finalPrice: 389.00,
          availableStock: 30,
        ),
        ProductVariantModel(
          id: '22222222-2222-2222-2222-22222222222b',
          sku: 'APX-SLV-STU',
          title: 'Silver Titanium',
          color: 'Silver Titanium',
          size: 'Over-Ear',
          priceAdjustment: 30.0,
          finalPrice: 419.00,
          availableStock: 18,
        ),
      ],
      rating: 4.8,
      reviewCount: 88,
    ),
    ProductDetailModel(
      id: '33333333-3333-3333-3333-333333333333',
      name: 'PrismBook Pro 16',
      slug: 'prismbook-pro-16',
      description:
          'Pro workstation laptop featuring blazing-fast unified architecture, Liquid Retina XDR display, studio microphones, and up to 22 hours of battery life.',
      basePrice: 1999.00,
      imageUrls: const [
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
        'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9',
      ],
      category: defaultCategories[1],
      variants: const [
        ProductVariantModel(
          id: '33333333-3333-3333-3333-33333333333a',
          sku: 'PBP-16-32G',
          title: 'Space Gray / 32GB',
          color: 'Space Gray',
          size: '16-inch 32GB',
          priceAdjustment: 0.0,
          finalPrice: 1999.00,
          availableStock: 15,
        ),
        ProductVariantModel(
          id: '33333333-3333-3333-3333-33333333333b',
          sku: 'PBP-16-64G',
          title: 'Silver / 64GB',
          color: 'Silver',
          size: '16-inch 64GB',
          priceAdjustment: 400.0,
          finalPrice: 2399.00,
          availableStock: 8,
        ),
      ],
      rating: 5.0,
      reviewCount: 64,
    ),
    ProductDetailModel(
      id: '44444444-4444-4444-4444-444444444444',
      name: 'Prism Watch Ultra',
      slug: 'prism-watch-ultra',
      description:
          'Rugged titanium aerospace GPS smartwatch with dual-frequency precision satellite tracking, dive-depth sensor, and 72-hour extended low-power mode.',
      basePrice: 499.00,
      imageUrls: const [
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
        'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1',
      ],
      category: defaultCategories[2],
      variants: const [
        ProductVariantModel(
          id: '44444444-4444-4444-4444-44444444444a',
          sku: 'PWU-OBS-49',
          title: 'Obsidian / 49mm',
          color: 'Obsidian',
          size: '49mm Titanium',
          priceAdjustment: 0.0,
          finalPrice: 499.00,
          availableStock: 25,
        ),
        ProductVariantModel(
          id: '44444444-4444-4444-4444-44444444444b',
          sku: 'PWU-ORG-49',
          title: 'Trail Orange / 49mm',
          color: 'Trail Orange',
          size: '49mm Titanium',
          priceAdjustment: 30.0,
          finalPrice: 529.00,
          availableStock: 6,
        ),
      ],
      rating: 4.9,
      reviewCount: 97,
    ),
  ];

  /// Retrieves list of categories from backend API with graceful fallback to seed categories.
  Future<List<CategoryModel>> getCategories() async {
    if (fallbackOnly) {
      return defaultCategories;
    }

    try {
      final response = await _apiClient.get(ApiConstants.categories);
      if (response.data is List) {
        final rawList = response.data as List;
        return rawList
            .map((item) =>
                CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[CatalogRepository] Category API fetch failed, using fallback: $e');
    }

    return defaultCategories;
  }

  /// Retrieves products from backend with fallback to rich seed items.
  Future<List<ProductSummaryModel>> getProducts({
    String? categoryId,
    String? searchTerm,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    if (fallbackOnly) {
      return _getFallbackProducts(
        categoryId: categoryId,
        searchTerm: searchTerm,
      );
    }

    try {
      final queryParams = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }
      if (searchTerm != null && searchTerm.trim().isNotEmpty) {
        queryParams['searchTerm'] = searchTerm.trim();
      }

      final response = await _apiClient.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );

      if (response.data is List) {
        final rawList = response.data as List;
        return rawList
            .map((item) =>
                ProductSummaryModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[CatalogRepository] API fetch failed, using fallback catalog: $e');
    }

    // Graceful offline fallback
    return _getFallbackProducts(categoryId: categoryId, searchTerm: searchTerm);
  }

  /// Retrieves full product details by product ID with fallback to seed data.
  Future<ProductDetailModel> getProductById(String id) async {
    if (fallbackOnly) {
      return seedProductDetails.firstWhere(
        (p) => p.id == id,
        orElse: () => seedProductDetails.first,
      );
    }

    try {
      final response = await _apiClient.get('${ApiConstants.products}/$id');
      if (response.data is Map) {
        return ProductDetailModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } catch (e) {
      debugPrint('[CatalogRepository] Detail API fetch failed for $id, using fallback: $e');
    }

    final fallback = seedProductDetails.firstWhere(
      (p) => p.id == id,
      orElse: () => seedProductDetails.first,
    );
    return fallback;
  }

  List<ProductSummaryModel> _getFallbackProducts({
    String? categoryId,
    String? searchTerm,
  }) {
    var items = seedProductDetails.map((detail) {
      return ProductSummaryModel(
        id: detail.id,
        name: detail.name,
        slug: detail.slug,
        description: detail.description,
        basePrice: detail.basePrice,
        imageUrls: detail.imageUrls,
        categoryName: detail.category.name,
        variantCount: detail.variants.length,
        rating: detail.rating,
        reviewCount: detail.reviewCount,
      );
    }).toList();

    if (categoryId != null && categoryId.isNotEmpty) {
      items = items.where((p) {
        final cat = defaultCategories.firstWhere(
          (c) => c.id == categoryId || c.name.toLowerCase() == categoryId.toLowerCase(),
          orElse: () => const CategoryModel(id: '', name: '', slug: ''),
        );
        return p.categoryName.toLowerCase() == cat.name.toLowerCase() ||
            p.categoryName.toLowerCase() == categoryId.toLowerCase();
      }).toList();
    }

    if (searchTerm != null && searchTerm.trim().isNotEmpty) {
      final query = searchTerm.trim().toLowerCase();
      items = items.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query) ||
            p.categoryName.toLowerCase().contains(query);
      }).toList();
    }

    return items;
  }
}
