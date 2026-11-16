import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../checkout/data/models/order_response_model.dart';

/// 4-stage visual order tracking timeline widget.
/// Highlights past steps in emerald with checkmarks, the active stage in glowing cobalt,
/// and future milestones with muted indicators.
class OrderTrackingTimeline extends StatelessWidget {
  final OrderResponseModel order;

  const OrderTrackingTimeline({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCancelled = order.status.trim().toLowerCase() == 'cancelled';
    final activeStep = _calculateActiveStep(order.status);

    if (isCancelled) {
      return _buildCancelledState(context);
    }

    final steps = [
      const _TimelineStepData(
        stepNumber: 1,
        title: 'Order Placed',
        subtitle: 'Order received and recorded in inventory database',
      ),
      const _TimelineStepData(
        stepNumber: 2,
        title: 'Payment Confirmed',
        subtitle: 'Payment successfully captured via Stripe gateway',
      ),
      const _TimelineStepData(
        stepNumber: 3,
        title: 'Processing & Packed',
        subtitle: 'Hardware inspected, barcoded, and packed at fulfillment hub',
      ),
      const _TimelineStepData(
        stepNumber: 4,
        title: 'Shipped & Delivered',
        subtitle: 'Dispatched via insured express courier to delivery address',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.25 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Live Fulfillment Status',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.electricCobalt.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.electricCobalt.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.electricCobalt,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        color: AppColors.electricCobalt,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;
              final isCompleted = step.stepNumber < activeStep ||
                  (activeStep == 4 && order.status.trim().toLowerCase() == 'delivered');
              final isActive = step.stepNumber == activeStep &&
                  !(activeStep == 4 && order.status.trim().toLowerCase() == 'delivered');

              return _buildTimelineItem(
                context,
                step: step,
                isCompleted: isCompleted,
                isActive: isActive,
                isLast: isLast,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required _TimelineStepData step,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final colors = context.colors;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Node Icon & Vertical Connector Line
          Column(
            children: [
              _buildStepNode(context, isCompleted: isCompleted, isActive: isActive),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.emerald
                          : (isActive
                              ? AppColors.electricCobalt.withValues(alpha: 0.5)
                              : colors.cardBorder),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Step Title & Description
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          color: isCompleted || isActive
                              ? colors.textPrimary
                              : colors.textMuted,
                          fontSize: 13.5,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.electricCobalt.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: AppColors.electricCobalt,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      color: isCompleted || isActive
                          ? colors.textSecondary
                          : colors.textMuted.withValues(alpha: 0.7),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(
    BuildContext context, {
    required bool isCompleted,
    required bool isActive,
  }) {
    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.emerald,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.35),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 15,
        ),
      );
    }

    if (isActive) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.electricCobalt.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.electricCobalt,
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricCobalt.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.electricCobalt,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    // Pending Step Node
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colors.cardBorder,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: context.colors.textMuted.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledState(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.vibrantCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.vibrantCoral.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.vibrantCoral.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppColors.vibrantCoral,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Cancelled',
                  style: TextStyle(
                    color: AppColors.vibrantCoral,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This order was cancelled and any authorized payments have been refunded to the original payment method.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateActiveStep(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 1;
      case 'paid':
        return 2;
      case 'processing':
        return 3;
      case 'shipped':
        return 4;
      case 'delivered':
        return 4; // all completed
      default:
        return 1;
    }
  }
}

class _TimelineStepData {
  final int stepNumber;
  final String title;
  final String subtitle;

  const _TimelineStepData({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
  });
}
