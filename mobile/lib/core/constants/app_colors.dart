import 'package:flutter/material.dart';

/// Design tokens and color palette for PrismCommerce.
/// Matches the high-conversion modern dark theme specified in the architectural blueprint,
/// with support for dynamic ThemeExtensions and light mode tokens.
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces (Default / Dark tokens for backward compatibility)
  static const Color background = Color(0xFF0B0F19);
  static const Color cardBackground = Color(0xFF161E2E);
  static const Color cardBorder = Color(0xFF26334D);
  static const Color surface = Color(0xFF1E293B);

  // Brand Primaries
  static const Color electricCobalt = Color(0xFF2563EB);
  static const Color cobaltGradientStart = Color(0xFF2563EB);
  static const Color cobaltGradientEnd = Color(0xFF1D4ED8);

  // Accents & Status
  static const Color vibrantCoral = Color(0xFFF43F5E); // Discounts, alerts, badges
  static const Color emerald = Color(0xFF10B981);      // In stock, success
  static const Color amber = Color(0xFFF59E0B);        // Low stock, ratings, warnings

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Input & Component Borders
  static const Color inputBackground = Color(0xFF161E2E);
  static const Color inputBorder = Color(0xFF26334D);
  static const Color inputFocusBorder = Color(0xFF2563EB);
  static const Color divider = Color(0xFF26334D);

  // Shimmer Skeletons
  static const Color shimmerBase = Color(0xFF161E2E);
  static const Color shimmerHighlight = Color(0xFF26334D);

  // Gradients
  static const LinearGradient cobaltGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cobaltGradientStart, cobaltGradientEnd],
  );

  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
  );

  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient holographicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  /// Helper to access dynamic theme tokens from BuildContext.
  static AppThemeColors of(BuildContext context) => context.colors;
}

/// Dynamic theme extension defining semantic color tokens for Dark & Light modes.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color cardBackground;
  final Color cardBorder;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color inputBackground;
  final Color inputBorder;
  final Color divider;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final LinearGradient promoGradient;

  const AppThemeColors({
    required this.background,
    required this.cardBackground,
    required this.cardBorder,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.inputBackground,
    required this.inputBorder,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.promoGradient,
  });

  /// Dark Theme semantic color preset.
  static const dark = AppThemeColors(
    background: Color(0xFF0B0F19),
    cardBackground: Color(0xFF161E2E),
    cardBorder: Color(0xFF26334D),
    surface: Color(0xFF1E293B),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    inputBackground: Color(0xFF161E2E),
    inputBorder: Color(0xFF26334D),
    divider: Color(0xFF26334D),
    shimmerBase: Color(0xFF161E2E),
    shimmerHighlight: Color(0xFF26334D),
    promoGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E293B), Color(0xFF1E1B4B), Color(0xFF0F172A)],
    ),
  );

  /// Light Theme semantic color preset.
  static const light = AppThemeColors(
    background: Color(0xFFF8FAFC),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2E8F0),
    surface: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFE2E8F0),
    divider: Color(0xFFE2E8F0),
    shimmerBase: Color(0xFFE2E8F0),
    shimmerHighlight: Color(0xFFF8FAFC),
    promoGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
    ),
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? cardBackground,
    Color? cardBorder,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? inputBackground,
    Color? inputBorder,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
    LinearGradient? promoGradient,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      promoGradient: promoGradient ?? this.promoGradient,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      background: Color.lerp(background, other.background, t) ?? background,
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      textPrimary:
          Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      inputBackground:
          Color.lerp(inputBackground, other.inputBackground, t) ??
              inputBackground,
      inputBorder:
          Color.lerp(inputBorder, other.inputBorder, t) ?? inputBorder,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      shimmerBase:
          Color.lerp(shimmerBase, other.shimmerBase, t) ?? shimmerBase,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t) ??
              shimmerHighlight,
      promoGradient:
          LinearGradient.lerp(promoGradient, other.promoGradient, t) ??
              promoGradient,
    );
  }
}

/// Convenience extensions on [BuildContext] to access semantic theme tokens cleanly.
extension ThemeColorsX on BuildContext {
  /// The active [AppThemeColors] extension, defaulting to [AppThemeColors.dark].
  AppThemeColors get colors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.dark;

  /// True if the current theme brightness is [Brightness.dark].
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
