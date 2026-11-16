import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/catalog/bloc/catalog_bloc.dart';
import 'package:mobile/features/catalog/data/repositories/catalog_repository.dart';

void main() {
  late CatalogRepository repository;
  late CatalogBloc bloc;

  setUp(() {
    repository = CatalogRepository(fallbackOnly: true);
    bloc = CatalogBloc(catalogRepository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('CatalogBloc', () {
    test('initial state is CatalogInitial', () {
      expect(bloc.state, const CatalogInitial());
    });

    test('emits [CatalogLoading, CatalogLoaded] on CatalogStarted', () async {
      final expectedStates = [
        isA<CatalogLoading>(),
        isA<CatalogLoaded>().having(
          (s) => s.products.length,
          'products.length',
          greaterThanOrEqualTo(3),
        ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const CatalogStarted());
    });

    test('filters products when CategoryFilterSelected is added', () async {
      bloc.add(const CatalogStarted());
      await bloc.stream.firstWhere((s) => s is CatalogLoaded);

      bloc.add(const CategoryFilterSelected('Audio'));
      await expectLater(
        bloc.stream,
        emits(
          isA<CatalogLoaded>()
              .having((s) => s.selectedCategory, 'selectedCategory', 'Audio')
              .having(
                (s) => s.products.every((p) => p.categoryName == 'Audio'),
                'all audio',
                isTrue,
              ),
        ),
      );
    });

    test('filters products when SearchQueryChanged is added', () async {
      bloc.add(const CatalogStarted());
      await bloc.stream.firstWhere((s) => s is CatalogLoaded);

      bloc.add(const SearchQueryChanged('Apex'));
      await expectLater(
        bloc.stream,
        emits(
          isA<CatalogLoaded>()
              .having((s) => s.searchQuery, 'searchQuery', 'Apex')
              .having((s) => s.products.length, 'matches', 1)
              .having((s) => s.products.first.name, 'name', 'Apex Wireless'),
        ),
      );
    });

    test('clears search when SearchQueryCleared is added', () async {
      bloc.add(const CatalogStarted());
      await bloc.stream.firstWhere((s) => s is CatalogLoaded);

      bloc.add(const SearchQueryChanged('Apex'));
      await bloc.stream.firstWhere(
        (s) => s is CatalogLoaded && s.searchQuery == 'Apex',
      );

      bloc.add(const SearchQueryCleared());
      await expectLater(
        bloc.stream,
        emits(
          isA<CatalogLoaded>()
              .having((s) => s.searchQuery, 'searchQuery', '')
              .having((s) => s.products.length, 'all restored',
                  greaterThanOrEqualTo(3)),
        ),
      );
    });
  });
}
