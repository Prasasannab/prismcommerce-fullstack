import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../checkout/data/models/order_request_model.dart';
import '../../../checkout/data/repositories/checkout_repository.dart';
import '../../../checkout/presentation/widgets/order_confirmation_dialog.dart';
import '../../../checkout/presentation/widgets/slide_to_pay_widget.dart';
import '../../bloc/cart_bloc.dart';
import 'cart_item_tile.dart';

/// Modal bottom sheet presenting interactive cart line items, quantity adjustments,
/// promotional coupon code application, address entry, and the Slide-to-Pay checkout slider.
class CartSheet extends StatefulWidget {
  final CheckoutRepository? checkoutRepository;

  const CartSheet({
    super.key,
    this.checkoutRepository,
  });

  /// Static helper to display the cart bottom sheet cleanly.
  static Future<void> show(
    BuildContext context, {
    CheckoutRepository? checkoutRepository,
  }) {
    final cartBloc = context.read<CartBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider<CartBloc>.value(
        value: cartBloc,
        child: CartSheet(checkoutRepository: checkoutRepository),
      ),
    );
  }

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  late final CheckoutRepository _checkoutRepository;
  late final TextEditingController _promoController;
  late final TextEditingController _addressController;

  bool _isCheckingOut = false;
  bool _isOrderSuccess = false;
  String? _checkoutError;

  @override
  void initState() {
    super.initState();
    _checkoutRepository =
        widget.checkoutRepository ?? CheckoutRepository();
    _promoController = TextEditingController();
    _addressController = TextEditingController(
      text: '123 Market St, San Francisco, CA 94103',
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isNotEmpty) {
      context.read<CartBloc>().add(CartPromoCodeApplied(code));
    }
  }

  Future<void> _handleCheckout(CartState state) async {
    if (state.items.isEmpty || _isCheckingOut) return;

    setState(() {
      _isCheckingOut = true;
      _checkoutError = null;
    });

    final address = _addressController.text.trim().isEmpty
        ? '123 Market St, San Francisco, CA 94103'
        : _addressController.text.trim();

    final orderItems = state.items.map((item) {
      final variantId = item.variantId.isNotEmpty
          ? item.variantId
          : '00000000-0000-0000-0000-000000000001';
      return OrderItemRequestModel(
        productVariantId: variantId,
        quantity: item.quantity,
      );
    }).toList();

    final request = OrderRequestModel(
      shippingAddress: address,
      items: orderItems,
    );

    try {
      final orderResponse = await _checkoutRepository.placeOrder(request);

      if (mounted) {
        setState(() {
          _isCheckingOut = false;
          _isOrderSuccess = true;
        });

        // Clear cart in BLoC
        context.read<CartBloc>().add(const CartCleared());

        // Dismiss the bottom sheet
        Navigator.of(context).pop();

        // Present animated celebration order confirmation dialog
        OrderConfirmationDialog.show(
          context,
          order: orderResponse,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
          _checkoutError = 'Checkout error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: colors.cardBorder, width: 1.5),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Draggable Handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Sheet Header: Title, Clear, Close
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.electricCobalt.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.electricCobalt,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shopping Bag (${state.totalItemCount})',
                            key: const Key('cart_sheet_title'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            state.items.isEmpty
                                ? 'No items selected'
                                : '${state.items.length} unique products',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (state.items.isNotEmpty)
                        TextButton(
                          key: const Key('cart_clear_button'),
                          onPressed: () {
                            context.read<CartBloc>().add(const CartCleared());
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: AppColors.vibrantCoral,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: colors.textSecondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.cardBorder, height: 1),

                // Content Area: Empty state or Scrollable items & controls
                Expanded(
                  child: state.items.isEmpty
                      ? _buildEmptyCartView(colors)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Free Shipping Progress Alert Banner
                              _buildFreeShippingBanner(state),

                              // Cart Line Items List
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.items.length,
                                itemBuilder: (context, index) {
                                  final item = state.items[index];
                                  return CartItemTile(
                                    item: item,
                                    onQuantityChanged: (qty) {
                                      context.read<CartBloc>().add(
                                            CartItemQuantityUpdated(
                                              productId: item.productId,
                                              variantId: item.variantId,
                                              quantity: qty,
                                            ),
                                          );
                                    },
                                    onRemove: () {
                                      context.read<CartBloc>().add(
                                            CartItemRemoved(
                                              productId: item.productId,
                                              variantId: item.variantId,
                                            ),
                                          );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Promo Code Box
                              _buildPromoCodeSection(state, colors),

                              const SizedBox(height: 16),

                              // Shipping Delivery Address
                              _buildShippingAddressSection(colors),

                              const SizedBox(height: 16),

                              // Order Summary Table
                              _buildOrderSummarySection(state, colors),

                              if (_checkoutError != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.vibrantCoral
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.vibrantCoral,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColors.vibrantCoral,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _checkoutError!,
                                          style: const TextStyle(
                                            color: AppColors.vibrantCoral,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                ),

                // Bottom Sticky Slide-to-Pay Confirmation Section
                if (state.items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: colors.background,
                      border: Border(
                        top: BorderSide(color: colors.cardBorder, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.3 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SlideToPayWidget(
                      totalAmount: state.total,
                      isLoading: _isCheckingOut,
                      isCompleted: _isOrderSuccess,
                      onConfirmed: () => _handleCheckout(state),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCartView(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.cardBorder, width: 2),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: colors.textMuted,
                size: 54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Shopping Bag is Empty',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our high-performance hardware and audio gear to fill your bag.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('start_shopping_button'),
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCobalt,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Explore Catalog',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeShippingBanner(CartState state) {
    final hasFree = state.hasFreeShipping;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (hasFree ? AppColors.emerald : AppColors.amber)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (hasFree ? AppColors.emerald : AppColors.amber)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFree ? Icons.local_shipping_rounded : Icons.info_outline_rounded,
            color: hasFree ? AppColors.emerald : AppColors.amber,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasFree
                  ? '🎉 Qualified for FREE Standard Shipping!'
                  : 'Add \$${state.freeShippingDeficit.toStringAsFixed(2)} more to unlock FREE Shipping!',
              style: TextStyle(
                color: hasFree ? AppColors.emerald : AppColors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(CartState state, AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promotional Code',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (state.isPromoApplied)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.emerald,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${state.promoCode} applied (20% OFF)',
                  key: const Key('applied_promo_badge'),
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  key: const Key('remove_promo_button'),
                  onTap: () {
                    context.read<CartBloc>().add(const CartPromoCodeRemoved());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  key: const Key('promo_input_field'),
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter promo code (e.g. TECH)',
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                key: const Key('apply_promo_button'),
                onPressed: _applyPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricCobalt,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        if (state.promoError != null) ...[
          const SizedBox(height: 6),
          Text(
            state.promoError!,
            key: const Key('promo_error_text'),
            style: const TextStyle(
              color: AppColors.vibrantCoral,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShippingAddressSection(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Address',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          key: const Key('shipping_address_input'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.electricCobalt,
              size: 20,
            ),
            hintText: 'Street address, city, state, zip',
            hintStyle: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.cardBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection(CartState state, AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Subtotal',
            '\$${state.subtotal.toStringAsFixed(2)}',
            colors,
            valueKey: 'cart_subtotal_text',
          ),
          if (state.isPromoApplied) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Promo Discount (20%)',
              '-\$${state.promoDiscount.toStringAsFixed(2)}',
              colors,
              valueKey: 'cart_discount_text',
              valueColor: AppColors.emerald,
            ),
          ],
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Shipping',
            state.shipping == 0.0
                ? 'FREE'
                : '\$${state.shipping.toStringAsFixed(2)}',
            colors,
            valueKey: 'cart_shipping_text',
            valueColor: state.shipping == 0.0
                ? AppColors.emerald
                : colors.textPrimary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: colors.cardBorder, height: 1),
          ),
          _buildSummaryRow(
            'Total',
            '\$${state.total.toStringAsFixed(2)}',
            colors,
            valueKey: 'cart_total_text',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    AppThemeColors colors, {
    String? valueKey,
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? colors.textPrimary : colors.textSecondary,
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          key: valueKey != null ? Key(valueKey) : null,
          style: TextStyle(
            color: valueColor ??
                (isTotal ? AppColors.emerald : colors.textPrimary),
            fontSize: isTotal ? 18 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
