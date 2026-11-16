import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Horizontal category selector bar with smooth pill filtering chips.
class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({
    super.key,
    this.categories = const [
      'All',
      'Audio',
      'Laptops',
      'Wearables',
      'Phones & Tablets',
      'Gaming & VR',
      'Accessories & Gear',
    ],
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected =
              category.toLowerCase() == selectedCategory.toLowerCase();

          return InkWell(
            key: Key('category_pill_$category'),
            onTap: () => onCategorySelected(category),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.cobaltGradient : null,
                color: isSelected ? null : colors.cardBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.electricCobalt : colors.cardBorder,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.electricCobalt.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_getCategoryIcon(category) != null) ...[
                      Icon(
                        _getCategoryIcon(category),
                        size: 14,
                        color: isSelected ? Colors.white : colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : colors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData? _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'laptops':
        return Icons.laptop_chromebook_rounded;
      case 'wearables':
        return Icons.watch_rounded;
      case 'phones & tablets':
      case 'phones':
        return Icons.phone_iphone_rounded;
      case 'gaming & vr':
      case 'gaming':
        return Icons.sports_esports_rounded;
      case 'accessories & gear':
      case 'accessories':
        return Icons.cable_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
