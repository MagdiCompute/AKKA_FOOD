import 'package:flutter/material.dart';

/// AKKA Food brand colors derived from the logo (royal blue + white).
abstract final class AppColors {
  /// Primary royal blue from the logo background.
  static const Color primaryBlue = Color(0xFF2B6CB0);

  /// Darker blue for contrast and depth.
  static const Color darkBlue = Color(0xFF1A4B7A);

  /// Lighter blue for surfaces and containers.
  static const Color lightBlue = Color(0xFF4A9FE5);

  /// Accent gold for highlights, badges, and CTAs.
  static const Color accentGold = Color(0xFFF5A623);

  /// Pure white — used for text on blue backgrounds.
  static const Color white = Color(0xFFFFFFFF);

  /// Off-white for backgrounds.
  static const Color offWhite = Color(0xFFF8FAFC);

  /// Light grey for cards and surfaces.
  static const Color surfaceGrey = Color(0xFFF1F5F9);

  /// Text colors.
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
}

/// Creates the AKKA Food light theme.
///
/// Based on the brand's royal blue color palette with gold accents.
/// Uses Material 3 design tokens.
ThemeData akkaFoodTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryBlue,
    primary: AppColors.primaryBlue,
    onPrimary: AppColors.white,
    secondary: AppColors.accentGold,
    onSecondary: AppColors.textDark,
    surface: AppColors.white,
    onSurface: AppColors.textDark,
    surfaceContainerHighest: AppColors.surfaceGrey,
    error: const Color(0xFFDC2626),
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.offWhite,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 0.5,
      ),
    ),

    // Navigation Bar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMedium,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primaryBlue, size: 24);
        }
        return const IconThemeData(color: AppColors.textMedium, size: 24);
      }),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.white,
    ),

    // Filled buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceGrey,
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceGrey,
      thickness: 1,
    ),

    // Text theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textMedium,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textLight,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlue,
      ),
    ),
  );
}
