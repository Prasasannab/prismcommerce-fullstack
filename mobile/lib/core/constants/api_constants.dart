import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration, base URLs, and route endpoints for PrismCommerce backend.
class ApiConstants {
  ApiConstants._();

  /// Automatically resolves base URL depending on runtime platform:
  /// - Android Emulator requires 10.0.2.2 to reach host machine localhost.
  /// - iOS Simulator, macOS Desktop, and Web use localhost.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5202/api/v1';
    }
    return 'http://localhost:5202/api/v1';
  }

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Authentication Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';

  // Catalog Endpoints
  static const String products = '/products';
  static const String categories = '/categories';

  // Orders & Checkout Endpoints
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';

  // Health Check
  static const String health = '/health';
}
