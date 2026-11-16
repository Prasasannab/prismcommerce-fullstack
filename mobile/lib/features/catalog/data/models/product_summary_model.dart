import 'package:equatable/equatable.dart';

/// Lightweight product representation for high-performance catalog grids and search results.
class ProductSummaryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String description;
  final double basePrice;
  final List<String> imageUrls;
  final String categoryName;
  final int variantCount;
  final double rating;
  final int reviewCount;

  const ProductSummaryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.basePrice,
    required this.imageUrls,
    required this.categoryName,
    required this.variantCount,
    this.rating = 4.8,
    this.reviewCount = 94,
  });

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imageUrls'] ?? json['ImageUrls'];
    final List<String> images = [];
    if (rawImages is List) {
      images.addAll(rawImages.map((e) => e.toString()));
    }

    return ProductSummaryModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      slug: (json['slug'] ?? json['Slug'] ?? '').toString(),
      description:
          (json['description'] ?? json['Description'] ?? '').toString(),
      basePrice:
          (json['basePrice'] ?? json['BasePrice'] as num?)?.toDouble() ?? 0.0,
      imageUrls: images,
      categoryName:
          (json['categoryName'] ?? json['CategoryName'] ?? '').toString(),
      variantCount:
          (json['variantCount'] ?? json['VariantCount'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 94,
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
      'categoryName': categoryName,
      'variantCount': variantCount,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  String get formattedPrice => '\$${basePrice.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        basePrice,
        imageUrls,
        categoryName,
        variantCount,
        rating,
        reviewCount,
      ];
}
