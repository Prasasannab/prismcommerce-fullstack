import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_auth_repo_test_');
    Hive.init(tempDir.path);
    final settingsBox = await Hive.openBox<dynamic>(
      '${StorageService.settingsBoxName}_auth_repo_test',
    );
    final cartBox = await Hive.openBox<dynamic>(
      '${StorageService.cartBoxName}_auth_repo_test',
    );

    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  group('AuthRepository', () {
    test('login successfully authenticates and stores tokens + user profile',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/login')) {
              final body = options.data as Map;
              expect(body['email'], 'john@example.com');
              expect(body['password'], 'Password123!');

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'accessToken': 'jwt-access-token-live',
                    'refreshToken': 'jwt-refresh-token-live',
                    'expiresAt': '2026-11-20T12:00:00Z',
                    'user': {
                      'id': 'user-1234',
                      'email': 'john@example.com',
                      'firstName': 'John',
                      'lastName': 'Doe',
                      'role': 'Customer',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = AuthRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final user = await repository.login('john@example.com', 'Password123!');

      expect(user.id, 'user-1234');
      expect(user.fullName, 'John Doe');
      expect(storageService.getAuthToken(), 'jwt-access-token-live');
      expect(storageService.getRefreshToken(), 'jwt-refresh-token-live');
      expect(storageService.getUser()?['email'], 'john@example.com');
    });

    test('login falls back to demo customer account when offline network error occurs',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'Connection refused',
              ),
            );
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = AuthRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final user = await repository.login(
        AuthRepository.demoEmail,
        AuthRepository.demoPassword,
      );

      expect(user.email, AuthRepository.demoEmail);
      expect(user.fullName, 'Alex Mercer');
      expect(storageService.getAuthToken(), contains('demo'));
      expect(storageService.getUser()?['email'], AuthRepository.demoEmail);
    });

    test('login rethrows ApiException when credentials are wrong on server',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {
                    'title': 'Unauthorized',
                    'detail': 'Invalid email or password.',
                  },
                ),
              ),
            );
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = AuthRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      expect(
        () => repository.login('wrong@example.com', 'WrongPass!'),
        throwsA(isA<ApiException>()),
      );
    });

    test('register successfully registers user and stores tokens', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/register')) {
              final body = options.data as Map;
              expect(body['firstName'], 'Sarah');
              expect(body['lastName'], 'Connor');
              expect(body['email'], 'sarah@example.com');
              expect(body['password'], 'Password123!');

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'accessToken': 'jwt-sarah-token',
                    'refreshToken': 'refresh-sarah-token',
                    'user': {
                      'id': 'sarah-123',
                      'email': 'sarah@example.com',
                      'firstName': 'Sarah',
                      'lastName': 'Connor',
                      'role': 'Customer',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = AuthRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final user = await repository.register(
        'Sarah',
        'Connor',
        'sarah@example.com',
        'Password123!',
      );

      expect(user.id, 'sarah-123');
      expect(user.fullName, 'Sarah Connor');
      expect(storageService.getAuthToken(), 'jwt-sarah-token');
      expect(storageService.getUser()?['firstName'], 'Sarah');
    });

    test('checkAuthStatus returns null when no token is saved', () async {
      final repository = AuthRepository(storageService: storageService);
      final user = await repository.checkAuthStatus();
      expect(user, isNull);
    });

    test('checkAuthStatus returns user when token exists and /auth/me succeeds',
        () async {
      await storageService.saveAuthToken('valid_live_token');

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/me')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'user-live-88',
                    'email': 'live@prismcommerce.com',
                    'firstName': 'Live',
                    'lastName': 'User',
                    'role': 'Customer',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = AuthRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final user = await repository.checkAuthStatus();
      expect(user, isNotNull);
      expect(user!.email, 'live@prismcommerce.com');
      expect(storageService.getUser()?['email'], 'live@prismcommerce.com');
    });

    test('checkAuthStatus clears tokens and returns null when token expired (401)',
        () async {
      await storageService.saveAuthToken('expired_token');
      await storageService.saveUser({'id': 'cached-id', 'email': 'exp@prism.com'});

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/me')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 401,
                  ),
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = AuthRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final user = await repository.checkAuthStatus();
      expect(user, isNull);
      expect(storageService.getAuthToken(), isNull);
      expect(storageService.getUser(), isNull);
    });

    test('checkAuthStatus falls back to cached user profile on network error',
        () async {
      await storageService.saveAuthToken('valid_token_but_offline');
      await storageService.saveUser({
        'id': 'cached-99',
        'email': 'cached@prismcommerce.com',
        'firstName': 'Cached',
        'lastName': 'Profile',
      });

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      final apiClient = ApiClient(dio: dio, storageService: storageService);
      final repository = AuthRepository(
        apiClient: apiClient,
        storageService: storageService,
      );

      final user = await repository.checkAuthStatus();
      expect(user, isNotNull);
      expect(user!.email, 'cached@prismcommerce.com');
      expect(user.fullName, 'Cached Profile');
    });

    test('logout clears tokens and cached user', () async {
      await storageService.saveAuthToken('token_to_purge');
      await storageService.saveRefreshToken('refresh_to_purge');
      await storageService.saveUser({'id': 'u1'});

      final repository = AuthRepository(storageService: storageService);
      await repository.logout();

      expect(storageService.getAuthToken(), isNull);
      expect(storageService.getRefreshToken(), isNull);
      expect(storageService.getUser(), isNull);
    });
  });
}
