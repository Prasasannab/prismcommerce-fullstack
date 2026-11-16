import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../cart/bloc/cart_bloc.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../cart/presentation/widgets/cart_sheet.dart';
import '../../bloc/catalog_bloc.dart';
import '../../data/models/product_summary_model.dart';
import '../../data/repositories/catalog_repository.dart';
import '../widgets/catalog_header.dart';
import '../widgets/category_selector.dart';
import '../widgets/product_card.dart';
import '../widgets/product_shimmer_grid.dart';
import '../widgets/promo_banner.dart';
import 'product_detail_screen.dart';

/// Main Catalog Screen for PrismCommerce.
/// Delivers an ultra-fast headless shopping experience featuring sticky search,
/// category filters, responsive product grid, and dynamic Hero animations.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshCartCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshCartCount() {
    try {
      final cart = StorageService.instance.getCart();
      final count = cart.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1),
      );
      if (mounted) {
        setState(() {
          _cartItemCount = count;
        });
      }
    } catch (_) {}
  }

  CartBloc? _getCartBloc(BuildContext context) {
    try {
      return context.read<CartBloc>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleQuickAdd(ProductSummaryModel product) async {
    final cartItem = CartItemModel(
      productId: product.id,
      variantId: '',
      productName: product.name,
      variantTitle: '',
      sku: product.slug,
      price: product.basePrice,
      quantity: 1,
      imageUrl: product.primaryImageUrl,
    );

    final cartBloc = _getCartBloc(context);
    if (cartBloc != null) {
      cartBloc.add(CartItemAdded(cartItem));
    }

    final storage = StorageService.instance;
    final cart = storage.getCart();
    final existingIndex = cart.indexWhere(
      (item) => item['productId'] == product.id,
    );

    if (existingIndex >= 0) {
      final currentQty =
          (cart[existingIndex]['quantity'] as num?)?.toInt() ?? 1;
      cart[existingIndex]['quantity'] = currentQty + 1;
    } else {
      cart.add(cartItem.toJson());
    }

    await storage.saveCart(cart);
    _refreshCartCount();

    if (mounted) {
      final colors = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: colors.cardBackground,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.emerald, width: 1),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added 1 × ${product.name} to bag',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openCartBottomSheet() {
    _refreshCartCount();
    final cartBloc = _getCartBloc(context);
    if (cartBloc != null) {
      CartSheet.show(context).then((_) => _refreshCartCount());
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => BlocProvider<CartBloc>(
          create: (_) => CartBloc()..add(const CartStarted()),
          child: const CartSheet(),
        ),
      ).then((_) => _refreshCartCount());
    }
  }

  void _navigateToDetail(ProductSummaryModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          productId: product.id,
          initialProduct: product,
          catalogRepository: context.read<CatalogRepository>(),
        ),
      ),
    ).then((_) => _refreshCartCount());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header with Search, Theme Toggle & Cart
            Builder(
              builder: (context) {
                final cartBloc = _getCartBloc(context);
                if (cartBloc != null) {
                  return BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      return CatalogHeader(
                        searchController: _searchController,
                        cartItemCount: cartState.totalItemCount,
                        onSearchChanged: (query) {
                          context
                              .read<CatalogBloc>()
                              .add(SearchQueryChanged(query));
                        },
                        onSearchCleared: () {
                          context
                              .read<CatalogBloc>()
                              .add(const SearchQueryCleared());
                        },
                        onCartPressed: _openCartBottomSheet,
                      );
                    },
                  );
                }
                return CatalogHeader(
                  searchController: _searchController,
                  cartItemCount: _cartItemCount,
                  onSearchChanged: (query) {
                    context.read<CatalogBloc>().add(SearchQueryChanged(query));
                  },
                  onSearchCleared: () {
                    context.read<CatalogBloc>().add(const SearchQueryCleared());
                  },
                  onCartPressed: _openCartBottomSheet,
                );
              },
            ),

            // Scrollable Catalog Content
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  if (state is CatalogInitial || state is CatalogLoading) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        PromoBanner(),
                        SizedBox(height: 8),
                        ProductShimmerGrid(),
                      ],
                    );
                  }

                  if (state is CatalogError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.vibrantCoral,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<CatalogBloc>()
                                    .add(const CatalogStarted());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is CatalogLoaded) {
                    final products = state.products;

                    return RefreshIndicator(
                      color: AppColors.electricCobalt,
                      backgroundColor: colors.cardBackground,
                      onRefresh: () async {
                        context
                            .read<CatalogBloc>()
                            .add(const CatalogRefreshed());
                      },
                      child: CustomScrollView(
                        slivers: [
                          // Promo Flash Sale Banner
                          const SliverToBoxAdapter(
                            child: PromoBanner(),
                          ),

                          // Category Selector Pills
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 12),
                              child: CategorySelector(
                                categories: state.categories.isNotEmpty
                                    ? ['All', ...state.categories.map((c) => c.name)]
                                    : const [
                                        'All',
                                        'Audio',
                                        'Laptops',
                                        'Wearables',
                                        'Phones & Tablets',
                                        'Gaming & VR',
                                        'Accessories & Gear',
                                      ],
                                selectedCategory: state.selectedCategory,
                                onCategorySelected: (cat) {
                                  context
                                      .read<CatalogBloc>()
                                      .add(CategoryFilterSelected(cat));
                                },
                              ),
                            ),
                          ),

                          // Active Filter Indicator / Count Row
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    state.selectedCategory == 'All'
                                        ? 'All Products'
                                        : '${state.selectedCategory} Collection',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${products.length}',
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (state.hasActiveFilter)
                                    InkWell(
                                      onTap: () {
                                        _searchController.clear();
                                        context.read<CatalogBloc>().add(
                                              const CategoryFilterSelected(
                                                'All',
                                              ),
                                            );
                                        context.read<CatalogBloc>().add(
                                              const SearchQueryCleared(),
                                            );
                                      },
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(
                                          color: AppColors.electricCobalt,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Product Grid or Empty State
                          if (products.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 60,
                                  horizontal: 24,
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        color: colors.textMuted,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No matching products found',
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Try adjusting your search terms or selecting another category.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          context.read<CatalogBloc>().add(
                                                const CategoryFilterSelected(
                                                  'All',
                                                ),
                                              );
                                          context.read<CatalogBloc>().add(
                                                const SearchQueryCleared(),
                                              );
                                        },
                                        child: const Text('Show All Products'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.65,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final product = products[index];
                                    return ProductCard(
                                      product: product,
                                      onTap: () => _navigateToDetail(product),
                                      onQuickAdd: () =>
                                          _handleQuickAdd(product),
                                    );
                                  },
                                  childCount: products.length,
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 24),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
