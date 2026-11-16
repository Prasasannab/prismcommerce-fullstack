import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Repository managing user authentication, registration, session verification,
/// token persistence, and offline fallback resilience.
class AuthRepository {
  final ApiClient _apiClient;
  final StorageService? storageService;

  static const String demoEmail = 'customer@prismcommerce.com';
  static const String demoPassword = 'Customer123!';
  static const UserModel demoUser = UserModel(
    id: '33333333-3333-3333-3333-333333333333',
    email: demoEmail,
    firstName: 'Alex',
    lastName: 'Mercer',
    role: 'Customer',
  );

  AuthRepository({
    ApiClient? apiClient,
    this.storageService,
  }) : _apiClient = apiClient ?? ApiClient();

  StorageService? get _storage {
    if (storageService != null) return storageService;
    try {
      return StorageService.instance;
    } catch (_) {
      return null;
    }
  }

  /// Authenticates user with email and password.
  /// On success, persists tokens and user profile to local storage.
  /// If the backend is offline or network error occurs during testing,
  /// falls back gracefully to the demo customer account.
  Future<UserModel> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    try {
      final response = await _apiClient.post(
        ApiConstants.authLogin,
        data: {
          'email': cleanEmail,
          'password': cleanPassword,
        },
      );

      if (response.data is Map) {
        final authResponse = AuthResponseModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        await _storage?.saveAuthToken(authResponse.accessToken);
        await _storage?.saveRefreshToken(authResponse.refreshToken);
        await _storage?.saveUser(authResponse.user.toJson());
        return authResponse.user;
      }
      throw ApiException(message: 'Invalid response received from authentication server.');
    } catch (e) {
      debugPrint('[AuthRepository] Login failed: $e');

      // Offline resilience fallback for local testing & demos
      final isDemoCreds = cleanEmail.toLowerCase() == demoEmail.toLowerCase() &&
          cleanPassword == demoPassword;

      if (isDemoCreds) {
        debugPrint('[AuthRepository] Using demo customer offline fallback.');
        const mockAccessToken = 'mock-jwt-token-demo-alex-mercer';
        const mockRefreshToken = 'mock-refresh-token-demo-alex-mercer';
        await _storage?.saveAuthToken(mockAccessToken);
        await _storage?.saveRefreshToken(mockRefreshToken);
        await _storage?.saveUser(demoUser.toJson());
        return demoUser;
      }

      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Registers a new user account with first name, last name, email, and password.
  Future<UserModel> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    try {
      final response = await _apiClient.post(
        ApiConstants.authRegister,
        data: {
          'firstName': cleanFirst,
          'lastName': cleanLast,
          'email': cleanEmail,
          'password': cleanPassword,
        },
      );

      if (response.data is Map) {
        final authResponse = AuthResponseModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        await _storage?.saveAuthToken(authResponse.accessToken);
        await _storage?.saveRefreshToken(authResponse.refreshToken);
        await _storage?.saveUser(authResponse.user.toJson());
        return authResponse.user;
      }
      throw ApiException(message: 'Invalid response received from registration server.');
    } catch (e) {
      debugPrint('[AuthRepository] Register failed: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  /// Verifies current authentication status by checking saved tokens and calling /auth/me.
  /// Falls back to cached user profile if network is temporarily unreachable.
  Future<UserModel?> checkAuthStatus() async {
    final token = _storage?.getAuthToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiClient.get(ApiConstants.authMe);
      if (response.data is Map) {
        final user = UserModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        await _storage?.saveUser(user.toJson());
        return user;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Expired or revoked session
        await logout();
        return null;
      }
      debugPrint('[AuthRepository] checkAuthStatus API error: $e');
    } catch (e) {
      debugPrint('[AuthRepository] checkAuthStatus network error: $e');
    }

    // Offline / cached fallback
    final cachedMap = _storage?.getUser();
    if (cachedMap != null) {
      return UserModel.fromJson(cachedMap);
    }

    // Demo token fallback
    if (token.contains('demo')) {
      return demoUser;
    }

    return null;
  }

  /// Revokes active session and purges stored authentication tokens and cached user.
  Future<void> logout() async {
    await _storage?.clearAuthToken();
    await _storage?.clearRefreshToken();
    await _storage?.clearUser();
  }
}
