import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_cubit.dart';
import 'package:mobile/features/catalog/presentation/widgets/catalog_header.dart';

void main() {
  late StorageService storageService;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final tempDir = await Directory.systemTemp.createTemp('hive_test_theme_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>('${StorageService.settingsBoxName}_theme');
    final cartBox =
        await Hive.openBox<dynamic>('${StorageService.cartBoxName}_theme');
    storageService = StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  group('ThemeCubit State & Persistence', () {
    test('initializes with ThemeMode.dark by default when no preference saved',
        () {
      final cubit = ThemeCubit(storageService: storageService);
      expect(cubit.state, ThemeMode.dark);
      expect(storageService.getThemeMode(), ThemeMode.dark);
      cubit.close();
    });

    test('initializes with saved ThemeMode.light when persisted in storage',
        () async {
      await storageService.saveThemeMode(ThemeMode.light);
      final cubit = ThemeCubit(storageService: storageService);
      expect(cubit.state, ThemeMode.light);
      expect(storageService.getThemeMode(), ThemeMode.light);
      cubit.close();
    });

    test('toggleTheme switches from dark to light and persists to storage',
        () async {
      await storageService.saveThemeMode(ThemeMode.dark);
      final cubit = ThemeCubit(storageService: storageService);
      expect(cubit.state, ThemeMode.dark);

      cubit.toggleTheme();
      expect(cubit.state, ThemeMode.light);
      expect(storageService.getThemeMode(), ThemeMode.light);

      cubit.close();
    });

    test('toggleTheme switches from light to dark and persists to storage',
        () async {
      await storageService.saveThemeMode(ThemeMode.light);
      final cubit = ThemeCubit(storageService: storageService);
      expect(cubit.state, ThemeMode.light);

      cubit.toggleTheme();
      expect(cubit.state, ThemeMode.dark);
      expect(storageService.getThemeMode(), ThemeMode.dark);

      cubit.close();
    });

    test('setThemeMode sets and persists explicit ThemeMode', () async {
      final cubit = ThemeCubit(storageService: storageService);

      cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state, ThemeMode.light);
      expect(storageService.getThemeMode(), ThemeMode.light);

      cubit.setThemeMode(ThemeMode.system);
      expect(cubit.state, ThemeMode.system);
      expect(storageService.getThemeMode(), ThemeMode.system);

      cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state, ThemeMode.dark);
      expect(storageService.getThemeMode(), ThemeMode.dark);

      cubit.close();
    });
  });

  group('AppThemeColors & ThemeExtension', () {
    test('presets have correct background, card, and text tokens', () {
      expect(AppThemeColors.dark.background, const Color(0xFF0B0F19));
      expect(AppThemeColors.dark.cardBackground, const Color(0xFF161E2E));
      expect(AppThemeColors.dark.textPrimary, const Color(0xFFF8FAFC));

      expect(AppThemeColors.light.background, const Color(0xFFF8FAFC));
      expect(AppThemeColors.light.cardBackground, const Color(0xFFFFFFFF));
      expect(AppThemeColors.light.textPrimary, const Color(0xFF0F172A));
      expect(AppThemeColors.light.cardBorder, const Color(0xFFE2E8F0));
    });

    test('copyWith properly modifies specified fields', () {
      final copied = AppThemeColors.dark.copyWith(
        background: Colors.red,
        textPrimary: Colors.yellow,
      );

      expect(copied.background, Colors.red);
      expect(copied.textPrimary, Colors.yellow);
      expect(copied.cardBackground, AppThemeColors.dark.cardBackground);
    });

    test('lerp interpolates between extensions smoothly', () {
      final interpolated =
          AppThemeColors.dark.lerp(AppThemeColors.light, 0.5);

      expect(interpolated.background, isNot(AppThemeColors.dark.background));
      expect(interpolated.background, isNot(AppThemeColors.light.background));
    });

    testWidgets(
        'AppTheme ThemeData definitions include AppThemeColors extensions',
        (tester) async {
      expect(
        AppTheme.darkTheme.extension<AppThemeColors>(),
        isNotNull,
      );
      expect(
        AppTheme.lightTheme.extension<AppThemeColors>(),
        isNotNull,
      );
    });
  });

  group('Theme Toggle UI Interaction', () {
    testWidgets(
        'Tapping theme toggle button in CatalogHeader triggers ThemeCubit',
        (tester) async {
      late ThemeCubit cubit;
      await tester.runAsync(() async {
        await storageService.saveThemeMode(ThemeMode.dark);
        cubit = ThemeCubit(storageService: storageService);
      });
      final searchCtrl = TextEditingController();

      await tester.pumpWidget(
        BlocProvider<ThemeCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: Scaffold(
              body: CatalogHeader(
                searchController: searchCtrl,
                onSearchChanged: (_) {},
                onSearchCleared: () {},
                cartItemCount: 2,
                onCartPressed: () {},
              ),
            ),
          ),
        ),
      );

      final toggleFinder = find.byKey(const Key('theme_toggle_button'));
      expect(toggleFinder, findsOneWidget);
      expect(cubit.state, ThemeMode.dark);

      await tester.tap(toggleFinder);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(cubit.state, ThemeMode.light);

      await tester.tap(toggleFinder);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(cubit.state, ThemeMode.dark);

      cubit.close();
    });
  });
}
