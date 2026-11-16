import 'package:equatable/equatable.dart';
import '../data/models/category_model.dart';
import '../data/models/product_summary_model.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class CatalogInitial extends CatalogState {
  const CatalogInitial();
}

/// Loading state for initial fetch or heavy operations.
class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

/// Successfully loaded catalog state holding products, categories, active filters, and search queries.
class CatalogLoaded extends CatalogState {
  final List<ProductSummaryModel> products;
  final List<ProductSummaryModel> allProducts;
  final List<CategoryModel> categories;
  final String selectedCategory;
  final String searchQuery;
  final bool isRefreshing;

  const CatalogLoaded({
    required this.products,
    required this.allProducts,
    required this.categories,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  CatalogLoaded copyWith({
    List<ProductSummaryModel>? products,
    List<ProductSummaryModel>? allProducts,
    List<CategoryModel>? categories,
    String? selectedCategory,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return CatalogLoaded(
      products: products ?? this.products,
      allProducts: allProducts ?? this.allProducts,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  bool get hasActiveFilter =>
      selectedCategory != 'All' || searchQuery.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        products,
        allProducts,
        categories,
        selectedCategory,
        searchQuery,
        isRefreshing,
      ];
}

/// Error state when network/server encounters an unrecoverable issue.
class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}
