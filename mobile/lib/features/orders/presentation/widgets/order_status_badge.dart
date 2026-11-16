import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Distinctive visual badge displaying the lifecycle status of an order.
/// Incorporates semantic color coding, outline borders, and contextual icons.
class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _resolveConfig(status);

    return Container(
      key: Key('order_status_badge_${status.toLowerCase()}'),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: statusConfig.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusConfig.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusConfig.icon,
            size: isCompact ? 11 : 13,
            color: statusConfig.color,
          ),
          const SizedBox(width: 5),
          Text(
            statusConfig.label,
            style: TextStyle(
              color: statusConfig.color,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _resolveConfig(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return const _StatusConfig(
          label: 'Pending',
          color: AppColors.amber,
          icon: Icons.hourglass_top_rounded,
        );
      case 'paid':
        return const _StatusConfig(
          label: 'Paid',
          color: AppColors.electricCobalt,
          icon: Icons.credit_card_rounded,
        );
      case 'processing':
        return const _StatusConfig(
          label: 'Processing',
          color: AppColors.electricCobalt,
          icon: Icons.inventory_2_outlined,
        );
      case 'shipped':
        return const _StatusConfig(
          label: 'Shipped',
          color: Color(0xFF8B5CF6), // Purple
          icon: Icons.local_shipping_outlined,
        );
      case 'delivered':
        return const _StatusConfig(
          label: 'Delivered',
          color: AppColors.emerald,
          icon: Icons.check_circle_rounded,
        );
      case 'cancelled':
        return const _StatusConfig(
          label: 'Cancelled',
          color: AppColors.vibrantCoral,
          icon: Icons.cancel_outlined,
        );
      default:
        return _StatusConfig(
          label: status,
          color: AppColors.textSecondary,
          icon: Icons.info_outline,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
