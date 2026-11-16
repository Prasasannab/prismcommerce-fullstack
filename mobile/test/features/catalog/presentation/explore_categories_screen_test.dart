import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/core/storage/storage_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/catalog/bloc/catalog_bloc.dart';
import 'package:mobile/features/catalog/data/models/category_model.dart';
import 'package:mobile/features/catalog/data/repositories/catalog_repository.dart';
import 'package:mobile/features/catalog/presentation/screens/explore_categories_screen.dart';

class MockFailingCatalogRepository extends CatalogRepository {
  MockFailingCatalogRepository() : super(fallbackOnly: true);

  @override
  Future<List<CategoryModel>> getCategories() async {
    throw Exception('Simulated network failure');
  }
}

class MockCustomCatalogRepository extends CatalogRepository {
  final List<CategoryModel> categories;
  MockCustomCatalogRepository(this.categories) : super(fallbackOnly: true);

  @override
  Future<List<CategoryModel>> getCategories() async {
    return categories;
  }
}

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_explore_');
    Hive.init(tempDir.path);
    final settingsBox =
        await Hive.openBox<dynamic>(StorageService.settingsBoxName);
    final cartBox = await Hive.openBox<dynamic>(StorageService.cartBoxName);
    StorageService.initForTesting(
      settingsBox: settingsBox,
      cartBox: cartBox,
    );
  });

  Widget buildSubject({
    CatalogRepository? repository,
    ValueChanged<CategoryModel>? onCategorySelected,
  }) {
    final repo = repository ?? CatalogRepository(fallbackOnly: true);
    final bloc = CatalogBloc(catalogRepository: repo);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CatalogRepository>.value(value: repo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CatalogBloc>.value(
            value: bloc..add(const CatalogStarted()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: ExploreCategoriesScreen(
            catalogRepository: repo,
            onCategorySelected: onCategorySelected,
          ),
        ),
      ),
    );
  }

  group('ExploreCategoriesScreen', () {
    testWidgets('renders category cards, icons, descriptions, and pills',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header title
      expect(find.text('Explore Categories'), findsOneWidget);
      // Search input field
      expect(find.byKey(const Key('explore_search_field')), findsOneWidget);

      // Default categories present
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Laptops'), findsOneWidget);
      expect(find.text('Wearables'), findsOneWidget);

      // Product count pills
      expect(find.text('24+ Items'), findsOneWidget);
      expect(find.text('18+ Items'), findsOneWidget);
      expect(find.text('15+ Items'), findsOneWidget);
    });

    testWidgets('filters categories in real time as user types search query',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Enter search query "lap"
      await tester.enterText(
        find.byKey(const Key('explore_search_field')),
        'lap',
      );
      await tester.pumpAndSettle();

      // "Laptops" remains visible, Audio and Wearables are filtered out
      expect(find.text('Laptops'), findsOneWidget);
      expect(find.text('Audio'), findsNothing);
      expect(find.text('Wearables'), findsNothing);

      // Clear search button appears and works
      final clearButton = find.byKey(const Key('explore_search_clear'));
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All categories restored
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Laptops'), findsOneWidget);
      expect(find.text('Wearables'), findsOneWidget);
    });

    testWidgets('shows empty state when no categories match search query',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('explore_search_field')),
        'NonExistentCategoryXYZ',
      );
      await tester.pumpAndSettle();

      expect(find.text('No categories found'), findsOneWidget);
      expect(find.text('Try searching with a different term'), findsOneWidget);
    });

    testWidgets('triggers onCategorySelected callback when category card is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      CategoryModel? selected;
      await tester.pumpWidget(
        buildSubject(
          onCategorySelected: (cat) => selected = cat,
        ),
      );
      await tester.pumpAndSettle();

      final audioCard = find.byKey(
        const Key('category_card_00000000-0000-0000-0000-000000000001'),
      );
      expect(audioCard, findsOneWidget);
      await tester.tap(audioCard);
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.name, 'Audio');
    });

    testWidgets('renders error view with retry button when repository fails',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final failingRepo = MockFailingCatalogRepository();
      await tester.pumpWidget(buildSubject(repository: failingRepo));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load categories. Please try again.'),
          findsOneWidget);
      expect(find.byKey(const Key('explore_retry_button')), findsOneWidget);
    });
  });
}
