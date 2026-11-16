import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../catalog/presentation/screens/catalog_screen.dart';
import '../../../catalog/presentation/screens/explore_categories_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../profile/presentation/screens/account_screen.dart';

/// Persistent Bottom Navigation Shell maintaining state across Shop, Explore, Orders, and Account.
/// Utilizes [IndexedStack] to preserve state and avoid unnecessary re-fetches when switching tabs.
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  /// Inherited access to the shell state for programmatic tab switching from descendant screens.
  static MainNavigationShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationShellState>();
  }

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

class MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Programmatically switch active tab by index (0: Shop, 1: Explore, 2: Orders, 3: Account).
  void switchToTab(int index) {
    if (index >= 0 && index <= 3 && _currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  int get currentIndex => _currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final pages = [
      const CatalogScreen(),
      const ExploreCategoriesScreen(),
      OrdersScreen(
        onNavigateToShop: () => switchToTab(0),
      ),
      AccountScreen(
        onNavigateToOrders: () => switchToTab(2),
        onNavigateToShop: () => switchToTab(0),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          border: Border(
            top: BorderSide(
              color: colors.cardBorder,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: colors.cardBackground,
              indicatorColor: AppColors.electricCobalt.withValues(alpha: 0.14),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: AppColors.electricCobalt,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  );
                }
                return TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(
                    color: AppColors.electricCobalt,
                    size: 24,
                  );
                }
                return IconThemeData(
                  color: colors.textMuted,
                  size: 24,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: switchToTab,
              height: 65,
              destinations: const [
                NavigationDestination(
                  key: Key('nav_tab_shop'),
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Shop',
                ),
                NavigationDestination(
                  key: Key('nav_tab_explore'),
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                NavigationDestination(
                  key: Key('nav_tab_orders'),
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'My Orders',
                ),
                NavigationDestination(
                  key: Key('nav_tab_account'),
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
