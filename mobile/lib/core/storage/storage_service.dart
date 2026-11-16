import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Local persistence service powered by Hive for fast key-value storage.
/// Used for auth token storage, user preferences, theme persistence, and offline cart caching.
class StorageService {
  static const String settingsBoxName = 'settings';
  static const String cartBoxName = 'cart';

  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _cartItemsKey = 'cart_items';
  static const String _themeModeKey = 'theme_mode';
  static const String _userKey = 'auth_user';

  static StorageService? _instance;

  final Box<dynamic> settingsBox;
  final Box<dynamic> cartBox;

  StorageService._({
    required this.settingsBox,
    required this.cartBox,
  });

  /// Returns the singleton instance of [StorageService].
  /// [init] must be called first.
  static StorageService get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'StorageService has not been initialized. Call await StorageService.init() in main() first.',
      );
    }
    return inst;
  }

  /// Initializes StorageService with pre-opened boxes for testing or custom configuration.
  static StorageService initForTesting({
    required Box<dynamic> settingsBox,
    required Box<dynamic> cartBox,
  }) {
    final service = StorageService._(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
    _instance = service;
    return service;
  }

  /// Initializes Hive and opens required boxes.
  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    final cartBox = await Hive.openBox<dynamic>(cartBoxName);

    final service = StorageService._(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
    _instance = service;
    return service;
  }

  // --- Theme Mode Persistence ---

  /// Persists the active [ThemeMode] preference.
  Future<void> saveThemeMode(ThemeMode mode) async {
    final String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await settingsBox.put(_themeModeKey, modeString);
  }

  /// Retrieves the persisted [ThemeMode], defaulting to [ThemeMode.dark].
  ThemeMode getThemeMode() {
    final raw = settingsBox.get(_themeModeKey);
    if (raw == 'light') return ThemeMode.light;
    if (raw == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  // --- Auth Token Methods ---

  /// Persists JWT Bearer token into settings box.
  Future<void> saveAuthToken(String token) async {
    await settingsBox.put(_authTokenKey, token);
  }

  /// Retrieves the saved JWT token, or null if unauthenticated.
  String? getAuthToken() {
    final value = settingsBox.get(_authTokenKey);
    return value is String ? value : null;
  }

  /// Clears stored authentication token on sign out.
  Future<void> clearAuthToken() async {
    await settingsBox.delete(_authTokenKey);
  }

  /// Persists refresh token.
  Future<void> saveRefreshToken(String token) async {
    await settingsBox.put(_refreshTokenKey, token);
  }

  /// Retrieves refresh token.
  String? getRefreshToken() {
    final value = settingsBox.get(_refreshTokenKey);
    return value is String ? value : null;
  }

  /// Clears refresh token.
  Future<void> clearRefreshToken() async {
    await settingsBox.delete(_refreshTokenKey);
  }

  // --- User Profile Persistence ---

  /// Persists the cached user profile.
  Future<void> saveUser(Map<String, dynamic> user) async {
    await settingsBox.put(_userKey, user);
  }

  /// Retrieves the cached user profile, or null if unauthenticated.
  Map<String, dynamic>? getUser() {
    final value = settingsBox.get(_userKey);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Clears stored user profile.
  Future<void> clearUser() async {
    await settingsBox.delete(_userKey);
  }

  // --- Cart Cache Methods ---

  /// Caches full cart item list for offline resilience.
  Future<void> saveCart(List<Map<String, dynamic>> items) async {
    await cartBox.put(_cartItemsKey, items);
  }

  /// Retrieves cart item list from offline cache.
  List<Map<String, dynamic>> getCart() {
    final raw = cartBox.get(_cartItemsKey);
    if (raw == null) return <Map<String, dynamic>>[];
    if (raw is List) {
      return raw.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
        return <String, dynamic>{};
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// Empties local cart cache.
  Future<void> clearCart() async {
    await cartBox.delete(_cartItemsKey);
  }

  /// Clears all stored data in both boxes.
  Future<void> clearAll() async {
    await settingsBox.clear();
    await cartBox.clear();
  }
}
