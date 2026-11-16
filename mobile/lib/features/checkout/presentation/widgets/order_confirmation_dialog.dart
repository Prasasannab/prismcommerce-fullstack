import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../orders/presentation/screens/order_detail_screen.dart';
import '../../data/models/order_response_model.dart';

/// Modal dialog presented upon successful order placement.
/// Features celebratory scale animation, order details summary, and return to shopping.
class OrderConfirmationDialog extends StatelessWidget {
  final OrderResponseModel order;
  final VoidCallback? onContinueShopping;

  const OrderConfirmationDialog({
    super.key,
    required this.order,
    this.onContinueShopping,
  });

  /// Static helper to display the dialog cleanly.
  static Future<void> show(
    BuildContext context, {
    required OrderResponseModel order,
    VoidCallback? onContinueShopping,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderConfirmationDialog(
        order: order,
        onContinueShopping: onContinueShopping,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Celebration Checkmark
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.emerald, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.3),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.emerald,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title & Subtitle
            Text(
              'Order Placed Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your high-concurrency order has been reserved and queued for dispatch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Order Metadata Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Order Number',
                    value: order.orderNumber,
                    colors: colors,
                    valueKey: 'order_dialog_number',
                    isEmphasized: true,
                  ),
                  Divider(color: colors.cardBorder, height: 18),
                  _buildDetailRow(
                    label: 'Total Amount',
                    value: '\$${order.totalAmount.toStringAsFixed(2)}',
                    colors: colors,
                    valueKey: 'order_dialog_total',
                    valueColor: AppColors.emerald,
                    isEmphasized: true,
                  ),
                  Divider(color: colors.cardBorder, height: 18),
                  _buildDetailRow(
                    label: 'Payment Status',
                    value: order.paymentStatus.toUpperCase(),
                    colors: colors,
                    valueKey: 'order_dialog_payment_status',
                    valueColor: AppColors.electricCobalt,
                  ),
                  if (order.shippingAddress.isNotEmpty) ...[
                    Divider(color: colors.cardBorder, height: 18),
                    _buildDetailRow(
                      label: 'Delivery To',
                      value: order.shippingAddress,
                      colors: colors,
                      valueKey: 'order_dialog_address',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Track Order Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('order_track_order_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(order: order),
                    ),
                  );
                },
                icon: const Icon(Icons.timeline_rounded, size: 18),
                label: const Text(
                  'Track Order',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricCobalt,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Continue Shopping Action Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                key: const Key('order_continue_shopping_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onContinueShopping?.call();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.cardBorder, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required AppThemeColors colors,
    String? valueKey,
    Color? valueColor,
    bool isEmphasized = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            key: valueKey != null ? Key(valueKey) : null,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? colors.textPrimary,
              fontSize: 13,
              fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
