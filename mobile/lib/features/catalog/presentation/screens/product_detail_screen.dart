import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../cart/bloc/cart_bloc.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../cart/presentation/widgets/cart_sheet.dart';
import '../../data/models/product_detail_model.dart';
import '../../data/models/product_summary_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../data/repositories/catalog_repository.dart';

/// Screen displaying rich product details, dynamic variant matrix (color/size),
/// real-time SKU and inventory status updates, and interactive Add to Bag actions.
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final ProductSummaryModel? initialProduct;
  final CatalogRepository? catalogRepository;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
    this.catalogRepository,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final CatalogRepository _repository;
  ProductDetailModel? _productDetail;
  ProductVariantModel? _selectedVariant;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = true;
  String? _errorMessage;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.catalogRepository ?? CatalogRepository();
    _refreshCartCount();
    _loadProductDetail();
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

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _repository.getProductById(widget.productId);
      if (mounted) {
        setState(() {
          _productDetail = detail;
          _selectedVariant =
              detail.variants.isNotEmpty ? detail.variants.first : null;
          _quantity = (_selectedVariant?.availableStock ?? 0) > 0 ? 1 : 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load product details: $e';
          _isLoading = false;
        });
      }
    }
  }

  CartBloc? _getCartBloc(BuildContext context) {
    try {
      return context.read<CartBloc>();
    } catch (_) {
      return null;
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

  Future<void> _addToCart() async {
    final detail = _productDetail;
    final variant = _selectedVariant;
    if (detail == null || variant == null || _quantity <= 0) return;

    final cartItem = CartItemModel(
      productId: detail.id,
      variantId: variant.id,
      productName: detail.name,
      variantTitle: variant.title,
      sku: variant.sku,
      price: variant.finalPrice,
      quantity: _quantity,
      imageUrl: detail.primaryImageUrl,
      maxStock: variant.availableStock,
    );

    final cartBloc = _getCartBloc(context);
    if (cartBloc != null) {
      cartBloc.add(CartItemAdded(cartItem));
    }

    final storage = StorageService.instance;
    final cart = storage.getCart();
    final existingIndex = cart.indexWhere(
      (item) =>
          item['productId'] == detail.id && item['variantId'] == variant.id,
    );

    if (existingIndex >= 0) {
      final currentQty =
          (cart[existingIndex]['quantity'] as num?)?.toInt() ?? 1;
      cart[existingIndex]['quantity'] = currentQty + _quantity;
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
              const Icon(Icons.check_circle, color: AppColors.emerald, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added $_quantity × ${detail.name} (${variant.color ?? variant.title}) to your bag!',
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final productName =
        _productDetail?.name ?? widget.initialProduct?.name ?? 'Product Details';
    final categoryName = _productDetail?.category.name ??
        widget.initialProduct?.categoryName ??
        'General';
    final images = _productDetail?.imageUrls ??
        widget.initialProduct?.imageUrls ??
        const [];
    final currentImage = images.isNotEmpty
        ? images[_selectedImageIndex.clamp(0, images.length - 1)]
        : '';
    final activePrice = _selectedVariant?.finalPrice ??
        _productDetail?.basePrice ??
        widget.initialProduct?.basePrice ??
        0.0;
    final stock = _selectedVariant?.availableStock ??
        _productDetail?.totalStock ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          productName,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              final cartBloc = _getCartBloc(context);
              if (cartBloc != null) {
                return BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    final count = cartState.totalItemCount;
                    return IconButton(
                      icon: Badge(
                        label: Text('$count'),
                        isLabelVisible: count > 0,
                        backgroundColor: AppColors.vibrantCoral,
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: colors.textPrimary,
                        ),
                      ),
                      onPressed: _openCartBottomSheet,
                    );
                  },
                );
              }
              return IconButton(
                icon: Badge(
                  label: Text('$_cartItemCount'),
                  isLabelVisible: _cartItemCount > 0,
                  backgroundColor: AppColors.vibrantCoral,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: colors.textPrimary,
                  ),
                ),
                onPressed: _openCartBottomSheet,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _productDetail == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.electricCobalt,
                ),
              ),
            )
          : _errorMessage != null && _productDetail == null
              ? Center(
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
                        _errorMessage!,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProductDetail,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Image Section
                      Hero(
                        tag: 'product_image_${widget.productId}',
                        child: Container(
                          height: 330,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.cardBackground,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: context.isDarkMode ? 0.35 : 0.08,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(28),
                            ),
                            child: currentImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: currentImage,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppColors.electricCobalt,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        _buildImagePlaceholder(colors),
                                  )
                                : _buildImagePlaceholder(colors),
                          ),
                        ),
                      ),

                      // Image Thumbnails Carousel
                      if (images.length > 1) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: images.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final isSelected = _selectedImageIndex == index;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedImageIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.electricCobalt
                                          : colors.cardBorder,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: images[index],
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          _buildImagePlaceholder(colors),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category & Rating Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: colors.cardBorder),
                                  ),
                                  child: Text(
                                    categoryName.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.electricCobalt,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_productDetail?.rating ?? 4.9} (${_productDetail?.reviewCount ?? 128} reviews)',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Product Title
                            Text(
                              productName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Price and Live Stock Row
                            Row(
                              children: [
                                Text(
                                  '\$${activePrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.emerald,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                _buildStockIndicator(stock),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Real-time Live SKU Badge
                            if (_selectedVariant != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: colors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2_rounded,
                                      color: colors.textSecondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SKU: ${_selectedVariant!.sku}',
                                      key: const Key('product_detail_sku'),
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),

                            // Dynamic Variant Selector
                            if (_productDetail != null &&
                                _productDetail!.variants.isNotEmpty) ...[
                              Text(
                                'Select Variant',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _productDetail!.variants.map((v) {
                                  final isSelected =
                                      _selectedVariant?.id == v.id;
                                  return InkWell(
                                    key: Key('variant_chip_${v.sku}'),
                                    onTap: () {
                                      setState(() {
                                        _selectedVariant = v;
                                        if (_quantity > v.availableStock) {
                                          _quantity = v.availableStock > 0
                                              ? v.availableStock
                                              : 0;
                                        } else if (_quantity == 0 &&
                                            v.availableStock > 0) {
                                          _quantity = 1;
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.electricCobalt
                                                .withValues(alpha: 0.15)
                                            : colors.cardBackground,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.electricCobalt
                                              : colors.cardBorder,
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildColorDot(v.color, colors),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v.title,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? colors.textPrimary
                                                      : colors.textSecondary,
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '\$${v.finalPrice.toStringAsFixed(2)} • ${v.availableStock} in stock',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? AppColors.emerald
                                                      : colors.textMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Description Section
                            Text(
                              'Product Overview',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _productDetail?.description ??
                                  widget.initialProduct?.description ??
                                  'Experience ultra-premium performance designed for creators and tech enthusiasts.',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Quantity Stepper
                            Text(
                              'Quantity',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildStepperButton(
                                  icon: Icons.remove,
                                  colors: colors,
                                  onPressed: _quantity > 1
                                      ? () {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.cardBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    '$_quantity',
                                    key: const Key('quantity_value_text'),
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _buildStepperButton(
                                  icon: Icons.add,
                                  colors: colors,
                                  onPressed: _quantity < stock
                                      ? () {
                                          setState(() {
                                            _quantity++;
                                          });
                                        }
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Max: $stock units',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      // Sticky Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          border: Border(
            top: BorderSide(
              color: context.isDarkMode
                  ? colors.cardBorder.withValues(alpha: 0.8)
                  : colors.cardBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDarkMode ? 0.45 : 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PRICE',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${(activePrice * _quantity).toStringAsFixed(2)}',
                    key: const Key('total_price_text'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: stock > 0 ? AppColors.cobaltGradient : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: stock > 0
                          ? [
                              BoxShadow(
                                color: AppColors.electricCobalt
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton.icon(
                      key: const Key('add_to_bag_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stock > 0
                            ? Colors.transparent
                            : colors.surface,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        stock > 0 ? 'Add to Bag' : 'Out of Stock',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      onPressed: stock > 0 ? _addToCart : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator(int stock) {
    final Color badgeColor;
    final String label;

    if (stock > 10) {
      badgeColor = AppColors.emerald;
      label = '$stock in stock';
    } else if (stock > 0) {
      badgeColor = AppColors.amber;
      label = 'Only $stock left';
    } else {
      badgeColor = AppColors.vibrantCoral;
      label = 'Out of Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            key: const Key('stock_indicator_text'),
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(String? colorName, AppThemeColors colors) {
    Color dotColor = AppColors.electricCobalt;
    if (colorName != null) {
      final lower = colorName.toLowerCase();
      if (lower.contains('black') || lower.contains('obsidian')) {
        dotColor = Colors.black;
      } else if (lower.contains('white')) {
        dotColor = Colors.white;
      } else if (lower.contains('blue')) {
        dotColor = const Color(0xFF1D4ED8);
      } else if (lower.contains('gray') || lower.contains('silver')) {
        dotColor = const Color(0xFF94A3B8);
      } else if (lower.contains('orange')) {
        dotColor = const Color(0xFFF97316);
      }
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.cardBorder, width: 1.5),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required AppThemeColors colors,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.textPrimary,
        disabledForegroundColor: colors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(AppThemeColors colors) {
    return Container(
      color: colors.cardBackground,
      child: Center(
        child: Icon(
          Icons.devices_other_rounded,
          color: colors.textMuted,
          size: 48,
        ),
      ),
    );
  }
}
