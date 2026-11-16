import 'package:equatable/equatable.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers initial fetch of categories and products.
class CatalogStarted extends CatalogEvent {
  const CatalogStarted();
}

/// Pull-to-refresh event that re-fetches products while retaining current filter.
class CatalogRefreshed extends CatalogEvent {
  const CatalogRefreshed();
}

/// Filter catalog by selected category name ('All', 'Audio', 'Laptops', 'Wearables').
class CategoryFilterSelected extends CatalogEvent {
  final String categoryName;

  const CategoryFilterSelected(this.categoryName);

  @override
  List<Object?> get props => [categoryName];
}

/// Real-time search query update across name and descriptions.
class SearchQueryChanged extends CatalogEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Clears current search filter.
class SearchQueryCleared extends CatalogEvent {
  const SearchQueryCleared();
}
