import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';

/// Top header containing the brand title, theme toggle button, cart badge icon,
/// and real-time search input.
class CatalogHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final int cartItemCount;
  final VoidCallback onCartPressed;

  const CatalogHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.cartItemCount,
    required this.onCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: colors.background,
      child: Column(
        children: [
          // Branding, Theme Toggle & Cart Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppColors.cobaltGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricCobalt.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PrismCommerce',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'High-Concurrency Store',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Theme Toggle Button
              IconButton(
                key: const Key('theme_toggle_button'),
                tooltip:
                    isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey<bool>(isDark),
                    color: isDark ? AppColors.amber : AppColors.electricCobalt,
                    size: 22,
                  ),
                ),
                onPressed: () {
                  try {
                    context.read<ThemeCubit>().toggleTheme();
                  } catch (_) {}
                },
              ),
              // Cart Button with Live Badge
              IconButton(
                key: const Key('cart_badge_button'),
                icon: Badge(
                  label: Text(
                    '$cartItemCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  isLabelVisible: cartItemCount > 0,
                  backgroundColor: AppColors.vibrantCoral,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: colors.textPrimary,
                    size: 24,
                  ),
                ),
                onPressed: onCartPressed,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, value, _) {
              final hasQuery = value.text.isNotEmpty;
              return TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search high-concurrency catalog...',
                  hintStyle: TextStyle(
                    color: colors.textMuted,
                    fontSize: 14,
                  ),
                  fillColor: colors.inputBackground,
                  prefixIcon: Icon(
                    Icons.search,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            searchController.clear();
                            onSearchCleared();
                          },
                        )
                      : Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.cardBorder),
                          ),
                          child: Text(
                            '⌘K',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
