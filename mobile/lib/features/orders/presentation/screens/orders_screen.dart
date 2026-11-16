import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../navigation/presentation/screens/main_navigation_shell.dart';
import '../../bloc/orders_bloc.dart';
import '../widgets/order_card.dart';

/// Screen displaying customer order history, filterable by status,
/// with live tracking transitions and pull-to-refresh.
class OrdersScreen extends StatelessWidget {
  final VoidCallback? onNavigateToShop;

  const OrdersScreen({
    super.key,
    this.onNavigateToShop,
  });

  void _navigateToShop(BuildContext context) {
    if (onNavigateToShop != null) {
      onNavigateToShop!();
      return;
    }
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
                Icons.receipt_long_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'My Orders',
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
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            return _buildAuthenticatedOrdersView(context);
          }
          return _buildGuestOrdersPrompt(context);
        },
      ),
    );
  }

  Widget _buildAuthenticatedOrdersView(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Filter Chips Row
        _buildFilterBar(context),
        Divider(color: colors.cardBorder, height: 1),

        // Orders List / States with Pull-to-refresh
        Expanded(
          child: BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              if (state is OrdersLoading) {
                return _buildLoadingShimmer(context);
              }

              if (state is OrdersError) {
                return _buildErrorState(context, state.message);
              }

              if (state is OrdersLoaded) {
                if (state.filteredOrders.isEmpty) {
                  return _buildEmptyState(context, state.selectedStatus);
                }

                return RefreshIndicator(
                  color: AppColors.electricCobalt,
                  backgroundColor: colors.cardBackground,
                  onRefresh: () async {
                    context.read<OrdersBloc>().add(const OrdersRefreshed());
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    itemCount: state.filteredOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = state.filteredOrders[index];
                      return OrderCard(order: order);
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final filters = ['All', 'Active', 'Delivered', 'Cancelled'];

    return BlocBuilder<OrdersBloc, OrdersState>(
      buildWhen: (previous, current) {
        if (previous is OrdersLoaded && current is OrdersLoaded) {
          return previous.selectedStatus != current.selectedStatus;
        }
        return true;
      },
      builder: (context, state) {
        final currentFilter = state is OrdersLoaded
            ? (state.selectedStatus ?? 'All')
            : 'All';

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: filters.map((filter) {
              final isSelected = (filter == 'All' &&
                      (currentFilter == 'All' || currentFilter.isEmpty)) ||
                  currentFilter.toLowerCase() == filter.toLowerCase();

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  key: Key('order_filter_${filter.toLowerCase()}'),
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) {
                    context.read<OrdersBloc>().add(
                          OrderStatusFilterSelected(filter),
                        );
                  },
                  showCheckmark: false,
                  selectedColor: AppColors.electricCobalt,
                  backgroundColor: context.colors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.electricCobalt
                          : context.colors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : context.colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String? selectedFilter) {
    final colors = context.colors;
    final isFiltered = selectedFilter != null && selectedFilter != 'All';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.cardBorder),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: colors.textMuted,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No $selectedFilter Orders' : 'No Orders Yet',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'There are currently no orders under the "$selectedFilter" filter.'
                  : 'Looks like you have not placed any orders yet. Discover our latest high-concurrency gear!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              key: const Key('orders_start_shopping_button'),
              onPressed: () => _navigateToShop(context),
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.vibrantCoral,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Orders',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<OrdersBloc>().add(const OrdersStarted());
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final colors = context.colors;

    return Shimmer.fromColors(
      baseColor: colors.shimmerBase,
      highlightColor: colors.shimmerHighlight,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => Container(
          height: 160,
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestOrdersPrompt(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.electricCobalt.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.electricCobalt.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: AppColors.electricCobalt,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Track Your Orders',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your account to review past purchases and track ongoing deliveries in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 180,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.cobaltGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  key: const Key('orders_sign_in_button'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
