import 'package:equatable/equatable.dart';
import 'category_model.dart';
import 'product_variant_model.dart';

/// Detailed product entity with full variant matrix, high-res galleries, and inventory levels.
class ProductDetailModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String description;
  final double basePrice;
  final List<String> imageUrls;
  final CategoryModel category;
  final List<ProductVariantModel> variants;
  final double rating;
  final int reviewCount;

  const ProductDetailModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.basePrice,
    required this.imageUrls,
    required this.category,
    required this.variants,
    this.rating = 4.9,
    this.reviewCount = 128,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imageUrls'] ?? json['ImageUrls'];
    final List<String> images = [];
    if (rawImages is List) {
      images.addAll(rawImages.map((e) => e.toString()));
    }

    final rawVariants = json['variants'] ?? json['Variants'];
    final List<ProductVariantModel> variantsList = [];
    if (rawVariants is List) {
      variantsList.addAll(
        rawVariants.map(
          (e) => ProductVariantModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        ),
      );
    }

    final rawCategory = json['category'] ?? json['Category'];
    final CategoryModel categoryModel;
    if (rawCategory is Map) {
      categoryModel =
          CategoryModel.fromJson(Map<String, dynamic>.from(rawCategory));
    } else {
      categoryModel = CategoryModel(
        id: '',
        name: (json['categoryName'] ?? json['CategoryName'] ?? 'General')
            .toString(),
        slug: 'general',
      );
    }

    return ProductDetailModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      slug: (json['slug'] ?? json['Slug'] ?? '').toString(),
      description:
          (json['description'] ?? json['Description'] ?? '').toString(),
      basePrice:
          (json['basePrice'] ?? json['BasePrice'] as num?)?.toDouble() ?? 0.0,
      imageUrls: images,
      category: categoryModel,
      variants: variantsList,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 128,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'basePrice': basePrice,
      'imageUrls': imageUrls,
      'category': category.toJson(),
      'variants': variants.map((v) => v.toJson()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get formattedPrice => '\$${basePrice.toStringAsFixed(2)}';
  int get totalStock => variants.fold(0, (sum, v) => sum + v.availableStock);
  bool get isInStock => totalStock > 0;

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        basePrice,
        imageUrls,
        category,
        variants,
        rating,
        reviewCount,
      ];
}
