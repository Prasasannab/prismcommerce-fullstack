import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/screens/main_navigation_shell.dart';
import '../../bloc/catalog_bloc.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/catalog_repository.dart';

/// Screen allowing users to browse and search all product categories with real-time filtering.
/// Tapping a category switches directly to the Shop tab filtered by the selected category.
class ExploreCategoriesScreen extends StatefulWidget {
  final CatalogRepository? catalogRepository;
  final ValueChanged<CategoryModel>? onCategorySelected;

  const ExploreCategoriesScreen({
    super.key,
    this.catalogRepository,
    this.onCategorySelected,
  });

  @override
  State<ExploreCategoriesScreen> createState() => _ExploreCategoriesScreenState();
}

class _ExploreCategoriesScreenState extends State<ExploreCategoriesScreen> {
  late final CatalogRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.catalogRepository ??
        (context.mounted
            ? _tryReadRepository(context) ?? CatalogRepository()
            : CatalogRepository());
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  CatalogRepository? _tryReadRepository(BuildContext context) {
    try {
      return context.read<CatalogRepository>();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _repository.getCategories();
      if (!mounted) return;
      setState(() {
        _allCategories = categories;
        _applyFilter(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load categories. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _applyFilter(_searchController.text);
  }

  void _applyFilter(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredCategories = List.from(_allCategories);
      } else {
        _filteredCategories = _allCategories.where((c) {
          final nameMatch = c.name.toLowerCase().contains(clean);
          final descMatch =
              c.description != null && c.description!.toLowerCase().contains(clean);
          return nameMatch || descMatch;
        }).toList();
      }
    });
  }

  void _handleCategoryTap(CategoryModel category) {
    if (widget.onCategorySelected != null) {
      widget.onCategorySelected!(category);
      return;
    }

    // Default behavior: filter CatalogBloc and navigate to Shop tab
    try {
      context.read<CatalogBloc>().add(CategoryFilterSelected(category.name));
    } catch (_) {}

    MainNavigationShell.of(context)?.switchToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppColors.cobaltGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Explore Categories',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.cardBorder, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              key: const Key('explore_search_field'),
              controller: _searchController,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search categories...',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textMuted,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        key: const Key('explore_search_clear'),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.electricCobalt,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Categories List / Grid
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.electricCobalt,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.vibrantCoral,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('explore_retry_button'),
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricCobalt,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: colors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No categories found',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try searching with a different term',
                style: TextStyle(color: colors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.electricCobalt,
      onRefresh: _loadCategories,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _filteredCategories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    final colors = context.colors;
    final isDark = context.isDarkMode;
    final iconData = _getCategoryIcon(category.name);
    final gradient = _getCategoryGradient(category.name);

    return InkWell(
      key: Key('category_card_${category.id}'),
      onTap: () => _handleCategoryTap(category),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? colors.cardBorder.withValues(alpha: 0.8)
                : colors.cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Category Icon / Thumbnail with distinct gradient
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                iconData,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Category Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16.5,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Product count pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${category.productCount > 0 ? category.productCount : 15}+ Items',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (category.description != null &&
                      category.description!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      category.description!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Forward navigation chevron
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('audio') || lower.contains('headphone')) {
      return Icons.headphones_rounded;
    } else if (lower.contains('laptop') || lower.contains('computer')) {
      return Icons.laptop_mac_rounded;
    } else if (lower.contains('wearable') || lower.contains('watch')) {
      return Icons.watch_rounded;
    } else if (lower.contains('phone') || lower.contains('mobile') || lower.contains('tablet')) {
      return Icons.phone_iphone_rounded;
    } else if (lower.contains('gaming') || lower.contains('vr')) {
      return Icons.sports_esports_rounded;
    } else if (lower.contains('accessori') || lower.contains('gear')) {
      return Icons.cable_rounded;
    }
    return Icons.grid_view_rounded;
  }

  LinearGradient _getCategoryGradient(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('audio')) {
      return AppColors.cobaltGradient;
    } else if (lower.contains('laptop')) {
      return AppColors.violetGradient;
    } else if (lower.contains('wearable')) {
      return AppColors.emeraldGradient;
    } else if (lower.contains('phone')) {
      return AppColors.amberGradient;
    } else if (lower.contains('gaming')) {
      return AppColors.coralGradient;
    }
    return AppColors.cobaltGradient;
  }
}
