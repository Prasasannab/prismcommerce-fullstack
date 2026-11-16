import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/api_client.dart';

void main() {
  group('Core Design Tokens & Constants', () {
    test('AppColors tokens are properly configured', () {
      expect(AppColors.background.toARGB32(), 0xFF0B0F19);
      expect(AppColors.cardBackground.toARGB32(), 0xFF161E2E);
      expect(AppColors.cardBorder.toARGB32(), 0xFF26334D);
      expect(AppColors.surface.toARGB32(), 0xFF1E293B);
      expect(AppColors.electricCobalt.toARGB32(), 0xFF2563EB);
      expect(AppColors.vibrantCoral.toARGB32(), 0xFFF43F5E);
      expect(AppColors.emerald.toARGB32(), 0xFF10B981);
      expect(AppColors.amber.toARGB32(), 0xFFF59E0B);
    });

    test('ApiConstants contains correct route paths', () {
      expect(ApiConstants.authLogin, '/auth/login');
      expect(ApiConstants.authRegister, '/auth/register');
      expect(ApiConstants.authMe, '/auth/me');
      expect(ApiConstants.products, '/products');
      expect(ApiConstants.categories, '/categories');
      expect(ApiConstants.orders, '/orders');
      expect(ApiConstants.myOrders, '/orders/my-orders');
      expect(ApiConstants.baseUrl, isNotEmpty);
    });
  });

  group('Network & ApiException Mapping', () {
    test('Maps connection timeout to friendly message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 408);
      expect(apiException.message, contains('timed out'));
    });

    test('Maps connection error to server offline message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionError,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 503);
      expect(apiException.message, contains('Ensure PrismCommerce backend is running'));
    });

    test('Decodes ASP.NET ProblemDetails validation errors', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 400,
        data: {
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'errors': {
            'Email': ['The Email field is required.'],
            'Password': ['The Password field must be at least 6 characters.'],
          },
        },
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: response,
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 400);
      expect(apiException.message, 'The Email field is required.');
      expect(apiException.validationErrors?['Email']?.first, 'The Email field is required.');
      expect(apiException.validationErrors?['Password']?.first, 'The Password field must be at least 6 characters.');
    });

    test('Decodes 401 Unauthorized status cleanly', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/orders/my-orders'),
        statusCode: 401,
      );

      final dioException = DioException(
        requestOptions: RequestOptions(path: '/orders/my-orders'),
        response: response,
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 401);
      expect(apiException.message, contains('Session expired or unauthorized'));
    });
  });
}
