import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';
import '../../../navigation/presentation/screens/main_navigation_shell.dart';

/// Account Profile Screen delivering full user management, theme preferences,
/// order shortcuts, address management, and session control.
class AccountScreen extends StatefulWidget {
  final VoidCallback? onNavigateToOrders;
  final VoidCallback? onNavigateToShop;
  final String? initialShippingAddress;

  const AccountScreen({
    super.key,
    this.onNavigateToOrders,
    this.onNavigateToShop,
    this.initialShippingAddress,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late String _shippingAddress;

  @override
  void initState() {
    super.initState();
    _shippingAddress = widget.initialShippingAddress ??
        '742 Evergreen Terrace, Springfield, OR 97477';
  }

  void _navigateToOrders() {
    if (widget.onNavigateToOrders != null) {
      widget.onNavigateToOrders!();
      return;
    }
    MainNavigationShell.of(context)?.switchToTab(2);
  }

  void _openEditAddressDialog() {
    final streetController = TextEditingController(
      text: _shippingAddress.split(',').first.trim(),
    );
    final rest = _shippingAddress.contains(',')
        ? _shippingAddress.substring(_shippingAddress.indexOf(',') + 1).trim()
        : '';
    final cityStateZipController = TextEditingController(text: rest);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.cardBorder),
          ),
          title: Text(
            'Edit Shipping Address',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('edit_address_street_field'),
                controller: streetController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.electricCobalt),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('edit_address_city_field'),
                controller: cityStateZipController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'City, State, ZIP',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.electricCobalt),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              key: const Key('edit_address_save_button'),
              onPressed: () {
                final newStreet = streetController.text.trim();
                final newRest = cityStateZipController.text.trim();
                if (newStreet.isNotEmpty) {
                  setState(() {
                    _shippingAddress =
                        newRest.isNotEmpty ? '$newStreet, $newRest' : newStreet;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shipping address updated successfully'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.cardBorder),
          ),
          title: Text(
            'Change Password',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('change_password_current_field'),
                  controller: currentPasswordController,
                  obscureText: true,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.electricCobalt),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('change_password_new_field'),
                  controller: newPasswordController,
                  obscureText: true,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.electricCobalt),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('change_password_confirm_field'),
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: colors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.electricCobalt),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              key: const Key('change_password_save_button'),
              onPressed: () {
                final newPass = newPasswordController.text;
                final confirmPass = confirmPasswordController.text;
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: AppColors.vibrantCoral,
                    ),
                  );
                  return;
                }
                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: AppColors.vibrantCoral,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.colors;
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.cardBorder),
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of your PrismCommerce account?',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              key: const Key('sign_out_cancel_button'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              key: const Key('sign_out_confirm_button'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantCoral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        title: Text(
          'My Account',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.cardBorder, height: 1),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.electricCobalt,
              ),
            );
          }

          if (authState is AuthAuthenticated) {
            return _buildAuthenticatedView(context, authState);
          }

          return _buildUnauthenticatedView(context);
        },
      ),
    );
  }

  Widget _buildAuthenticatedView(
    BuildContext context,
    AuthAuthenticated authState,
  ) {
    final colors = context.colors;
    final user = authState.user;

    // Generate Initials
    String initials = 'U';
    if (user.firstName.isNotEmpty && user.lastName.isNotEmpty) {
      initials =
          '${user.firstName[0]}${user.lastName[0]}'.toUpperCase();
    } else if (user.fullName.isNotEmpty) {
      initials = user.fullName[0].toUpperCase();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Profile Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with Initials
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.cobaltGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricCobalt.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name, Email & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Role / Member Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.role.isNotEmpty ? user.role : 'Member',
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Stats Row: Orders Count, Member Status, Promo
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Orders',
                value: 'Live',
                icon: Icons.local_shipping_outlined,
                accentColor: AppColors.electricCobalt,
                onTap: _navigateToOrders,
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                title: 'Tier',
                value: 'VIP Pro',
                icon: Icons.workspace_premium_outlined,
                accentColor: AppColors.amber,
                onTap: null,
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                title: 'Promo',
                value: '20% OFF',
                icon: Icons.discount_outlined,
                accentColor: AppColors.vibrantCoral,
                onTap: widget.onNavigateToShop,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Shopping
        _buildSectionHeader('Shopping'),
        _buildSectionContainer(
          colors,
          [
            _buildNavigationTile(
              key: const Key('account_my_orders_tile'),
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.electricCobalt,
              title: 'My Orders',
              subtitle: 'Track active shipments and order history',
              onTap: _navigateToOrders,
            ),
            Divider(color: colors.cardBorder, height: 1),
            _buildNavigationTile(
              key: const Key('account_shipping_address_tile'),
              icon: Icons.local_shipping_outlined,
              iconColor: AppColors.amber,
              title: 'Saved Shipping Address',
              subtitle: _shippingAddress,
              onTap: _openEditAddressDialog,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Preferences
        _buildSectionHeader('Preferences'),
        _buildSectionContainer(
          colors,
          [
            _buildThemeToggleTile(context),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Account Settings
        _buildSectionHeader('Account Settings'),
        _buildSectionContainer(
          colors,
          [
            _buildNavigationTile(
              key: const Key('account_change_password_tile'),
              icon: Icons.lock_outline_rounded,
              iconColor: colors.textSecondary,
              title: 'Change Password',
              subtitle: 'Update your security credentials',
              onTap: _openChangePasswordDialog,
            ),
            Divider(color: colors.cardBorder, height: 1),
            _buildNavigationTile(
              key: const Key('account_sign_out_tile'),
              icon: Icons.logout_rounded,
              iconColor: AppColors.vibrantCoral,
              title: 'Sign Out',
              subtitle: 'Safely log out of this device',
              titleColor: AppColors.vibrantCoral,
              onTap: () => _showSignOutConfirmation(context),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Guest Welcome Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.electricCobalt.withValues(alpha: 0.18),
                      AppColors.electricCobalt.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.electricCobalt.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 36,
                  color: AppColors.electricCobalt,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to PrismCommerce',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to track orders, save shipping addresses, and unlock member discounts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Sign In Primary Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.cobaltGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricCobalt.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    key: const Key('account_sign_in_button'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
              const SizedBox(height: 10),

              // Create Account Outlined Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  key: const Key('account_register_button'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.electricCobalt,
                    side: const BorderSide(
                      color: AppColors.electricCobalt,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section: Preferences
        _buildSectionHeader('Preferences'),
        _buildSectionContainer(
          colors,
          [
            _buildThemeToggleTile(context),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
    AppThemeColors colors,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavigationTile({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.electricCobalt : AppColors.amber)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: isDark ? AppColors.electricCobalt : AppColors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Theme',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Dark mode enabled' : 'Light mode enabled',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            key: const Key('account_theme_switch'),
            value: isDark,
            activeTrackColor: AppColors.electricCobalt,
            onChanged: (val) {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onTap,
    required AppThemeColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
