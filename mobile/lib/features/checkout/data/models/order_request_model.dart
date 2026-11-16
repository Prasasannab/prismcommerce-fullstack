import 'package:equatable/equatable.dart';

/// Request item payload for placing an order via `/api/v1/orders`.
class OrderItemRequestModel extends Equatable {
  final String productVariantId;
  final int quantity;

  const OrderItemRequestModel({
    required this.productVariantId,
    required this.quantity,
  });

  factory OrderItemRequestModel.fromJson(Map<String, dynamic> json) {
    return OrderItemRequestModel(
      productVariantId: (json['productVariantId'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productVariantId': productVariantId,
      'quantity': quantity,
    };
  }

  @override
  List<Object?> get props => [productVariantId, quantity];
}

/// Request payload matching ASP.NET Core `PlaceOrderRequestDto`.
class OrderRequestModel extends Equatable {
  final String shippingAddress;
  final List<OrderItemRequestModel> items;

  const OrderRequestModel({
    required this.shippingAddress,
    required this.items,
  });

  factory OrderRequestModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return OrderRequestModel(
      shippingAddress: (json['shippingAddress'] ?? '').toString(),
      items: rawItems
          .map((item) =>
              OrderItemRequestModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shippingAddress': shippingAddress,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [shippingAddress, items];
}
