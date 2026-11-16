import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_storage_service_test_');
    Hive.init(tempDir.path);
    final settingsBox = await Hive.openBox<dynamic>(
      '${StorageService.settingsBoxName}_test_storage',
    );
    final cartBox = await Hive.openBox<dynamic>(
      '${StorageService.cartBoxName}_test_storage',
    );

    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  group('StorageService User Methods', () {
    test('getUser returns null when no user has been saved', () {
      expect(storageService.getUser(), isNull);
    });

    test('saveUser persists user map and getUser retrieves it', () async {
      final userMap = {
        'id': 'u-999',
        'email': 'test@prismcommerce.com',
        'firstName': 'Alex',
        'lastName': 'Mercer',
        'role': 'Customer',
      };

      await storageService.saveUser(userMap);
      final retrieved = storageService.getUser();

      expect(retrieved, isNotNull);
      expect(retrieved?['id'], 'u-999');
      expect(retrieved?['email'], 'test@prismcommerce.com');
      expect(retrieved?['firstName'], 'Alex');
    });

    test('clearUser removes saved user profile', () async {
      await storageService.saveUser({'id': 'u-1', 'email': 'user@prism.com'});
      expect(storageService.getUser(), isNotNull);

      await storageService.clearUser();
      expect(storageService.getUser(), isNull);
    });

    test('themeMode and token persistence operate independently', () async {
      await storageService.saveThemeMode(ThemeMode.light);
      expect(storageService.getThemeMode(), equals(ThemeMode.light));

      await storageService.saveAuthToken('token-123');
      expect(storageService.getAuthToken(), equals('token-123'));

      await storageService.clearAuthToken();
      expect(storageService.getAuthToken(), isNull);
      expect(storageService.getThemeMode(), equals(ThemeMode.light));
    });
  });
}
