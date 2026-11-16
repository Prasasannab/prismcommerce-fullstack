import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/features/orders/data/repositories/orders_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_orders_repo_test_');
    Hive.init(tempDir.path);
    final settingsBox = await Hive.openBox<dynamic>(
        '${StorageService.settingsBoxName}_orders_repo');
    final cartBox = await Hive.openBox<dynamic>(
        '${StorageService.cartBoxName}_orders_repo');

    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  group('OrdersRepository', () {
    test('getMyOrders successfully fetches from API and deserializes list',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/orders/my-orders')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'id': 'ord-test-100',
                      'orderNumber': 'ORD-2026-TEST',
                      'userId': 'usr-123',
                      'status': 'Delivered',
                      'paymentStatus': 'Succeeded',
                      'totalAmount': 349.99,
                      'shippingAddress': '456 Test Blvd, Seattle, WA',
                      'stripePaymentIntentId': 'pi_test_123456789',
                      'createdAt': '2026-11-14T12:00:00Z',
                      'items': [
                        {
                          'id': 'item-100',
                          'productVariantId': 'var-100',
                          'productName': 'Prism Audio Pods',
                          'variantTitle': 'Midnight Black',
                          'sku': 'PRM-POD-BLK',
                          'unitPrice': 349.99,
                          'quantity': 1,
                          'totalPrice': 349.99,
                        }
                      ],
                    }
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = OrdersRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final orders = await repository.getMyOrders();

      expect(orders.length, 1);
      expect(orders.first.id, 'ord-test-100');
      expect(orders.first.orderNumber, 'ORD-2026-TEST');
      expect(orders.first.status, 'Delivered');
      expect(orders.first.totalAmount, 349.99);
      expect(orders.first.items.first.productName, 'Prism Audio Pods');
    });

    test('getMyOrders falls back to realistic demo orders when API throws error',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Connection refused',
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = OrdersRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final orders = await repository.getMyOrders();

      expect(orders.isNotEmpty, isTrue);
      expect(
        orders.any((o) => o.orderNumber == 'ORD-20261113-C81E2E47'),
        isTrue,
      );
      expect(
        orders.any((o) => o.orderNumber == 'ORD-20261114-A59B1102'),
        isTrue,
      );
      expect(
        orders.any((o) => o.status == 'Delivered'),
        isTrue,
      );
      expect(
        orders.any((o) => o.status == 'Paid'),
        isTrue,
      );
    });

    test('fallbackOnly mode immediately returns demo orders without network',
        () async {
      final repository = OrdersRepository(
        storageService: storageService,
        fallbackOnly: true,
      );

      final orders = await repository.getMyOrders();

      expect(orders.length, 5);
      final deliveredOrder =
          orders.firstWhere((o) => o.orderNumber == 'ORD-20261113-C81E2E47');
      expect(deliveredOrder.status, 'Delivered');
      expect(deliveredOrder.items.first.productName, 'Prism Pulse Pods');
      expect(deliveredOrder.stripePaymentIntentId, isNotNull);
    });

    test('getOrderById fetches order from API or falls back to demo order',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/orders/ord-test-456')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'ord-test-456',
                    'orderNumber': 'ORD-FETCHED-456',
                    'userId': 'usr-789',
                    'status': 'Shipped',
                    'paymentStatus': 'Succeeded',
                    'totalAmount': 199.00,
                    'shippingAddress': '999 Mission St, San Francisco, CA',
                    'stripePaymentIntentId': 'pi_test_456',
                    'createdAt': '2026-11-15T08:00:00Z',
                    'items': [],
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = OrdersRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final order = await repository.getOrderById('ord-test-456');
      expect(order.orderNumber, 'ORD-FETCHED-456');
      expect(order.status, 'Shipped');

      // Test fallback resolution by order number
      final fallbackRepo = OrdersRepository(fallbackOnly: true);
      final fallbackOrder =
          await fallbackRepo.getOrderById('ORD-20261114-A59B1102');
      expect(fallbackOrder.orderNumber, 'ORD-20261114-A59B1102');
      expect(fallbackOrder.status, 'Paid');
      expect(fallbackOrder.totalAmount, 548.00);
    });
  });
}
