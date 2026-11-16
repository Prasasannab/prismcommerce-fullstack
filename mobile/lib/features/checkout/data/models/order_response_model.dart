import 'package:equatable/equatable.dart';

/// Item in the order confirmation response.
class OrderItemResponseModel extends Equatable {
  final String id;
  final String productVariantId;
  final String productName;
  final String variantTitle;
  final String sku;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  const OrderItemResponseModel({
    required this.id,
    required this.productVariantId,
    required this.productName,
    required this.variantTitle,
    required this.sku,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItemResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderItemResponseModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      productVariantId:
          (json['productVariantId'] ?? json['ProductVariantId'] ?? '').toString(),
      productName:
          (json['productName'] ?? json['ProductName'] ?? '').toString(),
      variantTitle:
          (json['variantTitle'] ?? json['VariantTitle'] ?? '').toString(),
      sku: (json['sku'] ?? json['Sku'] ?? '').toString(),
      unitPrice: (json['unitPrice'] ?? json['UnitPrice'] as num?)?.toDouble() ??
          0.0,
      quantity: (json['quantity'] ?? json['Quantity'] as num?)?.toInt() ?? 1,
      totalPrice:
          (json['totalPrice'] ?? json['TotalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productVariantId': productVariantId,
      'productName': productName,
      'variantTitle': variantTitle,
      'sku': sku,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productVariantId,
        productName,
        variantTitle,
        sku,
        unitPrice,
        quantity,
        totalPrice,
      ];
}

/// Response payload matching ASP.NET Core `OrderResponseDto`.
class OrderResponseModel extends Equatable {
  final String id;
  final String orderNumber;
  final String userId;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final String shippingAddress;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final List<OrderItemResponseModel> items;
  final String? clientSecret;

  const OrderResponseModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.shippingAddress,
    this.stripePaymentIntentId,
    required this.createdAt,
    required this.items,
    this.clientSecret,
  });

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] ?? json['Items']) as List? ?? [];
    final createdRaw = json['createdAt'] ?? json['CreatedAt'];
    DateTime parsedDate;
    if (createdRaw is String) {
      parsedDate = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return OrderResponseModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? json['OrderNumber'] ?? '').toString(),
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      status: (json['status'] ?? json['Status'] ?? 'Pending').toString(),
      paymentStatus:
          (json['paymentStatus'] ?? json['PaymentStatus'] ?? 'Pending').toString(),
      totalAmount:
          (json['totalAmount'] ?? json['TotalAmount'] as num?)?.toDouble() ??
              0.0,
      shippingAddress:
          (json['shippingAddress'] ?? json['ShippingAddress'] ?? '').toString(),
      stripePaymentIntentId: (json['stripePaymentIntentId'] ??
              json['StripePaymentIntentId'])
          ?.toString(),
      createdAt: parsedDate,
      items: rawItems
          .map((item) => OrderItemResponseModel.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
      clientSecret:
          (json['clientSecret'] ?? json['ClientSecret'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'status': status,
      'paymentStatus': paymentStatus,
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      'stripePaymentIntentId': stripePaymentIntentId,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'clientSecret': clientSecret,
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        userId,
        status,
        paymentStatus,
        totalAmount,
        shippingAddress,
        stripePaymentIntentId,
        createdAt,
        items,
        clientSecret,
      ];
}
