import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/checkout/data/models/order_request_model.dart';
import 'package:mobile/features/checkout/data/models/order_response_model.dart';

void main() {
  group('Checkout Models', () {
    test('OrderRequestModel serializes matching ASP.NET Core PlaceOrderRequestDto',
        () {
      const request = OrderRequestModel(
        shippingAddress: '123 Market St, San Francisco, CA 94103',
        items: [
          OrderItemRequestModel(
            productVariantId: '11111111-1111-1111-1111-11111111111a',
            quantity: 2,
          ),
        ],
      );

      final json = request.toJson();
      expect(json['shippingAddress'], '123 Market St, San Francisco, CA 94103');
      expect((json['items'] as List).length, 1);
      expect(
        (json['items'] as List).first['productVariantId'],
        '11111111-1111-1111-1111-11111111111a',
      );
      expect((json['items'] as List).first['quantity'], 2);

      final deserialized = OrderRequestModel.fromJson(json);
      expect(deserialized, equals(request));
    });

    test(
        'OrderResponseModel parses ASP.NET Core OrderResponseDto with RFC 3339 timestamps',
        () {
      final json = {
        'id': '99999999-9999-9999-9999-999999999999',
        'orderNumber': 'ORD-2026-0042',
        'userId': '88888888-8888-8888-8888-888888888888',
        'status': 'Pending',
        'paymentStatus': 'Authorized',
        'totalAmount': 249.00,
        'shippingAddress': '456 Mission St, San Francisco, CA',
        'stripePaymentIntentId': 'pi_test_12345',
        'createdAt': '2026-11-13T10:00:00Z',
        'items': [
          {
            'id': '77777777-7777-7777-7777-777777777777',
            'productVariantId': '11111111-1111-1111-1111-11111111111a',
            'productName': 'Prism Pulse Pods',
            'variantTitle': 'Space Black',
            'sku': 'PPP-BLK-PRO',
            'unitPrice': 249.00,
            'quantity': 1,
            'totalPrice': 249.00,
          }
        ],
        'clientSecret': 'seti_mock_secret',
      };

      final response = OrderResponseModel.fromJson(json);
      expect(response.id, '99999999-9999-9999-9999-999999999999');
      expect(response.orderNumber, 'ORD-2026-0042');
      expect(response.status, 'Pending');
      expect(response.paymentStatus, 'Authorized');
      expect(response.totalAmount, 249.00);
      expect(response.items.length, 1);
      expect(response.items.first.productName, 'Prism Pulse Pods');
      expect(response.clientSecret, 'seti_mock_secret');
    });
  });
}
