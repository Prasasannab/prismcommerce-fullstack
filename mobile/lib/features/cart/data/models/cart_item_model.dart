import 'package:equatable/equatable.dart';

/// Represents an individual item stored in the shopping cart.
class CartItemModel extends Equatable {
  final String productId;
  final String variantId;
  final String productName;
  final String variantTitle;
  final String sku;
  final double price;
  final int quantity;
  final String imageUrl;
  final int maxStock;

  const CartItemModel({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantTitle,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.maxStock = 99,
  });

  /// Total price for this line item (price * quantity).
  double get totalPrice => price * quantity;

  /// Display title combining product name and variant descriptor.
  String get displayTitle =>
      variantTitle.isNotEmpty ? '$productName ($variantTitle)' : productName;

  CartItemModel copyWith({
    String? productId,
    String? variantId,
    String? productName,
    String? variantTitle,
    String? sku,
    double? price,
    int? quantity,
    String? imageUrl,
    int? maxStock,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      variantTitle: variantTitle ?? this.variantTitle,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      maxStock: maxStock ?? this.maxStock,
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: (json['productId'] ?? '').toString(),
      variantId: (json['variantId'] ?? '').toString(),
      productName: (json['productName'] ?? json['title'] ?? '').toString(),
      variantTitle: (json['variantTitle'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: (json['imageUrl'] ?? '').toString(),
      maxStock: (json['maxStock'] as num?)?.toInt() ?? 99,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'variantTitle': variantTitle,
      'sku': sku,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'maxStock': maxStock,
      'title': displayTitle,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        variantId,
        productName,
        variantTitle,
        sku,
        price,
        quantity,
        imageUrl,
        maxStock,
      ];
}
