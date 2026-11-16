import 'package:equatable/equatable.dart';

/// Represents a specific SKU variant of a product (color, size, price adjustment, and live stock).
class ProductVariantModel extends Equatable {
  final String id;
  final String sku;
  final String title;
  final String? color;
  final String? size;
  final double priceAdjustment;
  final double finalPrice;
  final int availableStock;

  const ProductVariantModel({
    required this.id,
    required this.sku,
    required this.title,
    this.color,
    this.size,
    required this.priceAdjustment,
    required this.finalPrice,
    required this.availableStock,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      sku: (json['sku'] ?? json['Sku'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      color: (json['color'] ?? json['Color']) as String?,
      size: (json['size'] ?? json['Size']) as String?,
      priceAdjustment:
          (json['priceAdjustment'] ?? json['PriceAdjustment'] as num?)?.toDouble() ?? 0.0,
      finalPrice:
          (json['finalPrice'] ?? json['FinalPrice'] as num?)?.toDouble() ?? 0.0,
      availableStock:
          (json['availableStock'] ?? json['AvailableStock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'title': title,
      'color': color,
      'size': size,
      'priceAdjustment': priceAdjustment,
      'finalPrice': finalPrice,
      'availableStock': availableStock,
    };
  }

  bool get isInStock => availableStock > 0;
  bool get isLowStock => availableStock > 0 && availableStock <= 5;

  @override
  List<Object?> get props => [
        id,
        sku,
        title,
        color,
        size,
        priceAdjustment,
        finalPrice,
        availableStock,
      ];
}
