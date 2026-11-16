import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/product_summary_model.dart';
import '../data/repositories/catalog_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

export 'catalog_event.dart';
export 'catalog_state.dart';

/// Business Logic Component managing product catalog listing, real-time filtering,
/// search querying, and synchronization with backend services.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository catalogRepository;

  CatalogBloc({
    required this.catalogRepository,
  }) : super(const CatalogInitial()) {
    on<CatalogStarted>(_onCatalogStarted);
    on<CatalogRefreshed>(_onCatalogRefreshed);
    on<CategoryFilterSelected>(_onCategoryFilterSelected);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SearchQueryCleared>(_onSearchQueryCleared);
  }

  Future<void> _onCatalogStarted(
    CatalogStarted event,
    Emitter<CatalogState> emit,
  ) async {
    emit(const CatalogLoading());
    try {
      final categories = await catalogRepository.getCategories();
      final products = await catalogRepository.getProducts();

      emit(
        CatalogLoaded(
          products: products,
          allProducts: products,
          categories: categories,
          selectedCategory: 'All',
          searchQuery: '',
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(CatalogError('Failed to load product catalog: ${e.toString()}'));
    }
  }

  Future<void> _onCatalogRefreshed(
    CatalogRefreshed event,
    Emitter<CatalogState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CatalogLoaded) {
      add(const CatalogStarted());
      return;
    }

    emit(currentState.copyWith(isRefreshing: true));
    try {
      final products = await catalogRepository.getProducts();
      final filtered = _filterProducts(
        products,
        currentState.selectedCategory,
        currentState.searchQuery,
      );

      emit(
        currentState.copyWith(
          products: filtered,
          allProducts: products,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      // Retain existing state if refresh fails
      emit(currentState.copyWith(isRefreshing: false));
    }
  }

  void _onCategoryFilterSelected(
    CategoryFilterSelected event,
    Emitter<CatalogState> emit,
  ) {
    final currentState = state;
    if (currentState is! CatalogLoaded) return;

    final filtered = _filterProducts(
      currentState.allProducts,
      event.categoryName,
      currentState.searchQuery,
    );

    emit(
      currentState.copyWith(
        selectedCategory: event.categoryName,
        products: filtered,
      ),
    );
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<CatalogState> emit,
  ) {
    final currentState = state;
    if (currentState is! CatalogLoaded) return;

    final filtered = _filterProducts(
      currentState.allProducts,
      currentState.selectedCategory,
      event.query,
    );

    emit(
      currentState.copyWith(
        searchQuery: event.query,
        products: filtered,
      ),
    );
  }

  void _onSearchQueryCleared(
    SearchQueryCleared event,
    Emitter<CatalogState> emit,
  ) {
    final currentState = state;
    if (currentState is! CatalogLoaded) return;

    final filtered = _filterProducts(
      currentState.allProducts,
      currentState.selectedCategory,
      '',
    );

    emit(
      currentState.copyWith(
        searchQuery: '',
        products: filtered,
      ),
    );
  }

  List<ProductSummaryModel> _filterProducts(
    List<ProductSummaryModel> masterList,
    String category,
    String query,
  ) {
    var result = masterList;

    if (category != 'All') {
      result = result
          .where((p) => p.categoryName.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (query.trim().isNotEmpty) {
      final clean = query.trim().toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(clean) ||
                p.description.toLowerCase().contains(clean) ||
                p.categoryName.toLowerCase().contains(clean),
          )
          .toList();
    }

    return result;
  }
}
