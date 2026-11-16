import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../checkout/data/models/order_response_model.dart';
import '../../../navigation/presentation/screens/main_navigation_shell.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_tracking_timeline.dart';

/// Detailed view of a customer order showing real-time fulfillment timeline,
/// ordered line items with variant specs, shipping destination, and Stripe payment metadata.
class OrderDetailScreen extends StatelessWidget {
  final OrderResponseModel order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  void _showHelpBottomSheet(BuildContext context) {
    final colors = context.colors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricCobalt.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.electricCobalt,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'PrismCommerce Concierge',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Have questions regarding order #${order.orderNumber}?\nOur 24/7 dedicated support team is ready to assist with returns, delivery updates, or technical support.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.email_outlined, color: AppColors.electricCobalt),
                ),
                title: Text(
                  'support@prismcommerce.com',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Guaranteed 1-hour response SLA',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'support@prismcommerce.com'),
                  );
                  Navigator.pop(bottomSheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support email copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(bottomSheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCobalt,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToShop(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    MainNavigationShell.of(context)?.switchToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final formattedDate =
        DateFormat('MMMM dd, yyyy • hh:mm a').format(order.createdAt.toLocal());

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        leading: IconButton(
          key: const Key('order_detail_back_button'),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              order.orderNumber,
              key: const Key('order_detail_order_number'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: OrderStatusBadge(status: order.status),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.cardBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Date and ID Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.electricCobalt),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedDate,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.paymentStatus.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section 1: Fulfillment Tracking Timeline
            OrderTrackingTimeline(order: order),
            const SizedBox(height: 20),

            // Section 2: Line Items Card
            _buildItemsCard(context),
            const SizedBox(height: 20),

            // Section 3: Shipping Delivery Card
            _buildShippingCard(context),
            const SizedBox(height: 20),

            // Section 4: Payment Summary Card
            _buildPaymentCard(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          border: Border(top: BorderSide(color: colors.cardBorder, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('order_detail_need_help_button'),
                  onPressed: () => _showHelpBottomSheet(context),
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Need Help?'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.cardBorder, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('order_detail_continue_shopping_button'),
                  onPressed: () => _navigateToShop(context),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Shop More'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildItemsCard(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items in this Order',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'product' : 'products'}',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.cardBorder, height: 1),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: colors.cardBorder, height: 1),
            ),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.electricCobalt,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (item.variantTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.variantTitle,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
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
                                'SKU: ${item.sku}',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Qty: ${item.quantity}',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShippingCard(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.electricCobalt,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Shipping Destination',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.cardBorder, height: 1),
          const SizedBox(height: 12),
          Text(
            order.shippingAddress.isNotEmpty
                ? order.shippingAddress
                : '123 Market St, San Francisco, CA 94103',
            key: const Key('order_detail_shipping_address'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 14, color: AppColors.emerald),
                SizedBox(width: 6),
                Text(
                  'Insured Express Dispatch',
                  style: TextStyle(
                    color: AppColors.emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.electricCobalt,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Payment Summary',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.electricCobalt.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'STRIPE SECURE',
                  style: TextStyle(
                    color: AppColors.electricCobalt,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.cardBorder, height: 1),
          const SizedBox(height: 14),

          _buildSummaryRow(
            label: 'Subtotal',
            value: '\$${order.totalAmount.toStringAsFixed(2)}',
            colors: colors,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Shipping',
            value: 'FREE',
            colors: colors,
            valueColor: AppColors.emerald,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Taxes & Regulatory Duties',
            value: 'Included',
            colors: colors,
          ),
          const SizedBox(height: 12),
          Divider(color: colors.cardBorder, height: 1),
          const SizedBox(height: 12),
          _buildSummaryRow(
            label: 'Total Paid',
            value: '\$${order.totalAmount.toStringAsFixed(2)}',
            colors: colors,
            isEmphasized: true,
          ),
          if (order.stripePaymentIntentId != null &&
              order.stripePaymentIntentId!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tag_rounded,
                    size: 16,
                    color: AppColors.electricCobalt,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stripe ID: ',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      order.stripePaymentIntentId!,
                      key: const Key('order_detail_stripe_id'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: colors.textSecondary,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: order.stripePaymentIntentId!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment ID copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required AppThemeColors colors,
    Color? valueColor,
    bool isEmphasized = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: isEmphasized ? colors.textPrimary : colors.textMuted,
              fontSize: isEmphasized ? 14 : 12.5,
              fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isEmphasized ? colors.textPrimary : colors.textSecondary),
            fontSize: isEmphasized ? 17 : 13,
            fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
