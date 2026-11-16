import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/features/checkout/data/models/order_request_model.dart';
import 'package:mobile/features/checkout/data/repositories/checkout_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_checkout_repo_test_');
    Hive.init(tempDir.path);
    final settingsBox = await Hive.openBox<dynamic>(
        '${StorageService.settingsBoxName}_checkout_repo');
    final cartBox = await Hive.openBox<dynamic>(
        '${StorageService.cartBoxName}_checkout_repo');

    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  group('CheckoutRepository', () {
    test(
        'ensureAuthenticated auto-logs in with demo customer credentials when no token exists',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/login')) {
              final body = options.data as Map;
              expect(body['email'], CheckoutRepository.demoEmail);
              expect(body['password'], CheckoutRepository.demoPassword);

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'accessToken': 'mock_jwt_customer_token_777',
                    'refreshToken': 'mock_refresh_token_888',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = CheckoutRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      expect(storageService.getAuthToken(), isNull);

      final token = await repository.ensureAuthenticated();
      expect(token, 'mock_jwt_customer_token_777');
      expect(storageService.getAuthToken(), 'mock_jwt_customer_token_777');
    });

    test('ensureAuthenticated reuses existing auth token without extra login call',
        () async {
      await storageService.saveAuthToken('existing_valid_jwt_token');

      bool loginCalled = false;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/login')) {
              loginCalled = true;
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = CheckoutRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final token = await repository.ensureAuthenticated();
      expect(token, 'existing_valid_jwt_token');
      expect(loginCalled, isFalse);
    });

    test(
        'placeOrder successfully submits order to API endpoint and maps response',
        () async {
      await storageService.saveAuthToken('existing_valid_token');

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/orders')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'id': '11111111-2222-3333-4444-555555555555',
                    'orderNumber': 'ORD-2026-7890',
                    'userId': '66666666-7777-8888-9999-000000000000',
                    'status': 'Pending',
                    'paymentStatus': 'Authorized',
                    'totalAmount': 498.00,
                    'shippingAddress':
                        '123 Market St, San Francisco, CA 94103',
                    'stripePaymentIntentId': 'pi_test_live_sim_123',
                    'createdAt': '2026-11-13T10:00:00Z',
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
      final repository = CheckoutRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      const request = OrderRequestModel(
        shippingAddress: '123 Market St, San Francisco, CA 94103',
        items: [
          OrderItemRequestModel(
            productVariantId: 'var-1',
            quantity: 2,
          ),
        ],
      );

      final result = await repository.placeOrder(request);

      expect(result.id, '11111111-2222-3333-4444-555555555555');
      expect(result.orderNumber, 'ORD-2026-7890');
      expect(result.totalAmount, 498.00);
      expect(result.paymentStatus, 'Authorized');
    });

    test('placeOrder fallback generates confirmed order when offline',
        () async {
      final repository = CheckoutRepository(
        storageService: storageService,
        fallbackOnly: true,
      );

      const request = OrderRequestModel(
        shippingAddress: '789 Howard St, San Francisco, CA',
        items: [
          OrderItemRequestModel(
            productVariantId: '11111111-1111-1111-1111-11111111111a',
            quantity: 1,
          ),
        ],
      );

      final result = await repository.placeOrder(request);

      expect(result.orderNumber.startsWith('ORD-2026-'), isTrue);
      expect(result.shippingAddress, '789 Howard St, San Francisco, CA');
      expect(result.paymentStatus, 'Authorized');
      expect(result.items.length, 1);
    });
  });
}
