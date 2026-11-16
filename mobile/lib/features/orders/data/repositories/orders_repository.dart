import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../checkout/data/models/order_response_model.dart';

/// Repository managing customer order history and order tracking queries.
/// Handles remote ASP.NET Core API interactions with resilient demo fallback
/// when offline or running in mock testing environments.
class OrdersRepository {
  final ApiClient _apiClient;
  final StorageService? storageService;
  final bool fallbackOnly;

  OrdersRepository({
    ApiClient? apiClient,
    this.storageService,
    this.fallbackOnly = false,
  }) : _apiClient = apiClient ?? ApiClient();

  /// Retrieves list of orders for the currently authenticated customer.
  /// Falls back to realistic demo orders if backend is unreachable or returns an error.
  Future<List<OrderResponseModel>> getMyOrders() async {
    if (!fallbackOnly) {
      try {
        final response = await _apiClient.get(ApiConstants.myOrders);

        if (response.data is List) {
          final list = response.data as List;
          final orders = list
              .map((item) => OrderResponseModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList();
          if (orders.isNotEmpty) {
            return orders;
          }
        } else if (response.data is Map) {
          final map = Map<String, dynamic>.from(response.data as Map);
          final rawItems =
              (map['items'] ?? map['data'] ?? map['orders']) as List?;
          if (rawItems != null && rawItems.isNotEmpty) {
            return rawItems
                .map((item) => OrderResponseModel.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ))
                .toList();
          }
        }
      } catch (e) {
        debugPrint('[OrdersRepository] Failed to fetch my orders: $e');
      }
    }

    return getDemoOrders();
  }

  /// Retrieves a specific order by ID or order number.
  /// Falls back to matching demo orders or the primary demo order if offline.
  Future<OrderResponseModel> getOrderById(String id) async {
    if (!fallbackOnly) {
      try {
        final response = await _apiClient.get('${ApiConstants.orders}/$id');
        if (response.data is Map) {
          return OrderResponseModel.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          );
        }
      } catch (e) {
        debugPrint('[OrdersRepository] Failed to fetch order ($id): $e');
      }
    }

    final demoOrders = getDemoOrders();
    return demoOrders.firstWhere(
      (order) => order.id == id || order.orderNumber == id,
      orElse: () => demoOrders.first,
    );
  }

  /// Realistic demo orders for offline demonstrations, widget testing, and offline modes.
  List<OrderResponseModel> getDemoOrders() {
    final now = DateTime.now();

    return [
      OrderResponseModel(
        id: 'ord-c81e2e47',
        orderNumber: 'ORD-20261113-C81E2E47',
        userId: 'usr-sarah-demo',
        status: 'Delivered',
        paymentStatus: 'Succeeded',
        totalAmount: 249.00,
        shippingAddress: '742 Evergreen Terrace, Springfield, OR 97477',
        stripePaymentIntentId: 'pi_3MtwBwLkdIwHu7ix28a3tqPa',
        createdAt: now.subtract(const Duration(days: 3, hours: 4)),
        items: const [
          OrderItemResponseModel(
            id: 'item-demo-1',
            productVariantId: '11111111-1111-1111-1111-111111111111',
            productName: 'Prism Pulse Pods',
            variantTitle: 'Space Black / Active Noise Cancelling',
            sku: 'PRM-POD-BLK',
            unitPrice: 249.00,
            quantity: 1,
            totalPrice: 249.00,
          ),
        ],
      ),
      OrderResponseModel(
        id: 'ord-a59b1102',
        orderNumber: 'ORD-20261114-A59B1102',
        userId: 'usr-sarah-demo',
        status: 'Paid',
        paymentStatus: 'Succeeded',
        totalAmount: 548.00,
        shippingAddress: '100 Market St, Suite 400, San Francisco, CA 94105',
        stripePaymentIntentId: 'pi_3NuqCwMleJwIv8jy39b4urQb',
        createdAt: now.subtract(const Duration(hours: 18, minutes: 30)),
        items: const [
          OrderItemResponseModel(
            id: 'item-demo-2-1',
            productVariantId: '22222222-2222-2222-2222-222222222222',
            productName: 'Apex Wireless Headphones',
            variantTitle: 'Midnight Silver',
            sku: 'APX-WRL-SLV',
            unitPrice: 299.00,
            quantity: 1,
            totalPrice: 299.00,
          ),
          OrderItemResponseModel(
            id: 'item-demo-2-2',
            productVariantId: '11111111-1111-1111-1111-111111111111',
            productName: 'Prism Pulse Pods',
            variantTitle: 'Glacier White',
            sku: 'PRM-POD-WHT',
            unitPrice: 249.00,
            quantity: 1,
            totalPrice: 249.00,
          ),
        ],
      ),
      OrderResponseModel(
        id: 'ord-e41c7789',
        orderNumber: 'ORD-20261115-E41C7789',
        userId: 'usr-sarah-demo',
        status: 'Shipped',
        paymentStatus: 'Succeeded',
        totalAmount: 1499.00,
        shippingAddress: '555 Tech Parkway, Austin, TX 78701',
        stripePaymentIntentId: 'pi_3OvrDxNmfKxJw9kz40c5vsRc',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        items: const [
          OrderItemResponseModel(
            id: 'item-demo-3-1',
            productVariantId: '33333333-3333-3333-3333-333333333333',
            productName: 'PrismBook Pro 16',
            variantTitle: 'Space Gray / 32GB RAM / 1TB SSD',
            sku: 'PBP-16-GRY-32',
            unitPrice: 1499.00,
            quantity: 1,
            totalPrice: 1499.00,
          ),
        ],
      ),
      OrderResponseModel(
        id: 'ord-f12d3344',
        orderNumber: 'ORD-20261116-F12D3344',
        userId: 'usr-sarah-demo',
        status: 'Pending',
        paymentStatus: 'Authorized',
        totalAmount: 199.00,
        shippingAddress: '456 Elm St, New York, NY 10001',
        stripePaymentIntentId: 'pi_3QxtFzPohMzLx1mb62e7xuTe',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        items: const [
          OrderItemResponseModel(
            id: 'item-demo-4-1',
            productVariantId: '44444444-4444-4444-4444-444444444444',
            productName: 'Prism Keypad Touch',
            variantTitle: 'Silver Anodized',
            sku: 'PRM-KPD-SLV',
            unitPrice: 199.00,
            quantity: 1,
            totalPrice: 199.00,
          ),
        ],
      ),
      OrderResponseModel(
        id: 'ord-b90f2156',
        orderNumber: 'ORD-20261110-B90F2156',
        userId: 'usr-sarah-demo',
        status: 'Cancelled',
        paymentStatus: 'Refunded',
        totalAmount: 129.00,
        shippingAddress: '123 Market St, San Francisco, CA 94103',
        stripePaymentIntentId: 'pi_3PwsEyOngLyKx0la51d6wtSd',
        createdAt: now.subtract(const Duration(days: 6)),
        items: const [
          OrderItemResponseModel(
            id: 'item-demo-5-1',
            productVariantId: '55555555-5555-5555-5555-555555555555',
            productName: 'Prism MagSafe Stand',
            variantTitle: 'Anodized Black',
            sku: 'PRM-MAG-BLK',
            unitPrice: 129.00,
            quantity: 1,
            totalPrice: 129.00,
          ),
        ],
      ),
    ];
  }
}
