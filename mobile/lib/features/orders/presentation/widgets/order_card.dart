import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../checkout/data/models/order_response_model.dart';
import '../screens/order_detail_screen.dart';
import 'order_status_badge.dart';

/// Card widget presenting a summary of an order in the customer's order history list.
/// Features order number, live status badge, item thumbnail preview, item count,
/// total price, and navigation to detailed tracking.
class OrderCard extends StatelessWidget {
  final OrderResponseModel order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalItemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final itemsSummary = order.items.isNotEmpty
        ? order.items.map((i) => i.productName).toSet().join(', ')
        : 'Order Items';

    final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('order_card_${order.id}'),
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.25 : 0.05,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Number + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      order.orderNumber,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        fontFamily: 'monospace',
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 5),

              // Date subheader
              Text(
                formattedDate,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 12),
              Divider(color: colors.cardBorder, height: 1),
              const SizedBox(height: 12),

              // Content: Thumbnail previews & title description
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnails row
                  _buildThumbnailsPreview(context),
                  const SizedBox(width: 12),

                  // Item Title & Count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$totalItemCount ${totalItemCount == 1 ? 'item' : 'items'} total',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: colors.cardBorder, height: 1),
              const SizedBox(height: 12),

              // Footer: Total Amount & "View Details ›"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: AppColors.electricCobalt,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.electricCobalt,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailsPreview(BuildContext context) {
    final colors = context.colors;
    final itemsToShow = order.items.take(3).toList();
    final remaining = order.items.length - itemsToShow.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < itemsToShow.length; i++)
          Container(
            width: 40,
            height: 40,
            margin: EdgeInsets.only(right: (i < itemsToShow.length - 1 || remaining > 0) ? 6 : 0),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Icon(
              _getItemIcon(itemsToShow[i].productName),
              color: AppColors.electricCobalt,
              size: 20,
            ),
          ),
        if (remaining > 0)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Center(
              child: Text(
                '+$remaining',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getItemIcon(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('pod') || lower.contains('headphone') || lower.contains('audio')) {
      return Icons.headphones_rounded;
    } else if (lower.contains('laptop') || lower.contains('book')) {
      return Icons.laptop_mac_rounded;
    } else if (lower.contains('watch')) {
      return Icons.watch_rounded;
    } else if (lower.contains('keyboard') || lower.contains('keypad')) {
      return Icons.keyboard_rounded;
    }
    return Icons.devices_other_rounded;
  }
}
