/// ElyaNotes Design System - Theme Configuration
///
/// Light ve Dark tema tanımları.
/// Tüm değerler design token'larından alınır.
/// Hardcoded renk kullanımı yasaktır (Colors.white, Colors.black vb.).
///
/// Kullanım:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'tokens/index.dart';

/// ElyaNotes tema tanımları.
///
/// Light ve Dark temalar için ThemeData sağlar.
/// Hardcoded değer kullanımı yasaktır!
abstract class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════

  /// Light tema
  static ThemeData get light {
    final colorScheme = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: AppTypography.create(Brightness.light),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.surfaceLight,
      dividerColor: AppColors.outlineLight,
      appBarTheme: _appBarTheme(colorScheme: colorScheme, isLight: true),
      cardTheme: _cardTheme(isLight: true),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(
        colorScheme: colorScheme,
        isLight: true,
      ),
      floatingActionButtonTheme: _fabTheme(colorScheme: colorScheme),
      snackBarTheme: _snackBarTheme(isLight: true),
      dividerTheme: _dividerTheme(isLight: true),
      bottomNavigationBarTheme: _bottomNavTheme(isLight: true),
      navigationRailTheme: _navigationRailTheme(isLight: true),
      chipTheme: _chipTheme(isLight: true),
      dialogTheme: _dialogTheme(isLight: true),
      bottomSheetTheme: _bottomSheetTheme(isLight: true),
      popupMenuTheme: _popupMenuTheme(isLight: true),
      iconTheme: _iconTheme(isLight: true),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════

  /// Dark tema
  static ThemeData get dark {
    final colorScheme = _darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: AppTypography.create(Brightness.dark),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.outlineDark,
      appBarTheme: _appBarTheme(colorScheme: colorScheme, isLight: false),
      cardTheme: _cardTheme(isLight: false),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(
        colorScheme: colorScheme,
        isLight: false,
      ),
      floatingActionButtonTheme: _fabTheme(colorScheme: colorScheme),
      snackBarTheme: _snackBarTheme(isLight: false),
      dividerTheme: _dividerTheme(isLight: false),
      bottomNavigationBarTheme: _bottomNavTheme(isLight: false),
      navigationRailTheme: _navigationRailTheme(isLight: false),
      chipTheme: _chipTheme(isLight: false),
      dialogTheme: _dialogTheme(isLight: false),
      bottomSheetTheme: _bottomSheetTheme(isLight: false),
      popupMenuTheme: _popupMenuTheme(isLight: false),
      iconTheme: _iconTheme(isLight: false),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLOR SCHEMES
  // ══════════════════════════════════════════════════════════════════════════

  static ColorScheme get _lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.accent,
        onTertiary: AppColors.onAccent,
        tertiaryContainer: AppColors.accentContainer,
        onTertiaryContainer: AppColors.onAccentContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        surfaceContainerLowest: AppColors.surfaceContainerLowestLight,
        surfaceContainerLow: AppColors.surfaceContainerLowLight,
        surfaceContainer: AppColors.surfaceContainerLight,
        surfaceContainerHigh: AppColors.surfaceContainerHighLight,
        surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
        outline: AppColors.outlineLight,
        outlineVariant: AppColors.outlineVariantLight,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: AppColors.inverseSurfaceLight,
        inversePrimary: AppColors.inversePrimaryLight,
        surfaceTint: AppColors.primary,
      );

  static ColorScheme get _darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryDarkMode,
        onPrimary: AppColors.onPrimaryDarkMode,
        primaryContainer: AppColors.primaryContainerDarkMode,
        onPrimaryContainer: AppColors.onPrimaryContainerDarkMode,
        secondary: AppColors.secondaryDarkMode,
        onSecondary: AppColors.onSecondaryDarkMode,
        secondaryContainer: AppColors.secondaryContainerDarkMode,
        onSecondaryContainer: AppColors.onSecondaryContainerDarkMode,
        tertiary: Color(0xFFBAC8E3),
        onTertiary: Color(0xFF253148),
        tertiaryContainer: Color(0xFF3B4760),
        onTertiaryContainer: Color(0xFFD7E3FF),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
        surfaceContainerLow: AppColors.surfaceContainerLowDark,
        surfaceContainer: AppColors.surfaceContainerDark,
        surfaceContainerHigh: AppColors.surfaceContainerHighDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
        outline: AppColors.outlineDark,
        outlineVariant: AppColors.outlineVariantDark,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: AppColors.inverseSurfaceDark,
        inversePrimary: AppColors.inversePrimaryDark,
        surfaceTint: AppColors.primaryDarkMode,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // COMPONENT THEMES
  // ══════════════════════════════════════════════════════════════════════════

  static AppBarTheme _appBarTheme({
    required ColorScheme colorScheme,
    required bool isLight,
  }) {
    final brightness = isLight ? Brightness.light : Brightness.dark;
    return AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      titleTextStyle: AppTypography.create(brightness).titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
    );
  }

  static CardThemeData _cardTheme({required bool isLight}) => CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: isLight
            ? AppColors.surfaceContainerLowLight
            : AppColors.surfaceContainerLowDark,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        margin: EdgeInsets.zero,
      );

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize:
              const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          minimumSize:
              const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          side: const BorderSide(color: AppColors.primary),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          minimumSize:
              const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme({
    required ColorScheme colorScheme,
    required bool isLight,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: (isLight
                ? AppColors.surfaceContainerHighestLight
                : AppColors.surfaceContainerHighestDark)
            .withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  static FloatingActionButtonThemeData _fabTheme({
    required ColorScheme colorScheme,
  }) =>
      FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      );

  static SnackBarThemeData _snackBarTheme({required bool isLight}) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppColors.inverseSurfaceLight
            : AppColors.inverseSurfaceDark,
        actionTextColor:
            isLight ? AppColors.inversePrimaryLight : AppColors.inversePrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  static PopupMenuThemeData _popupMenuTheme({required bool isLight}) =>
      PopupMenuThemeData(
        color: isLight
            ? AppColors.surfaceContainerLowLight
            : AppColors.surfaceContainerLowDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      );

  static IconThemeData _iconTheme({required bool isLight}) => IconThemeData(
        color: isLight
            ? AppColors.textSecondaryLight
            : AppColors.textSecondaryDark,
        size: AppIconSize.lg,
      );

  static DividerThemeData _dividerTheme({required bool isLight}) =>
      DividerThemeData(
        color: isLight
            ? AppColors.outlineVariantLight
            : AppColors.outlineVariantDark,
        thickness: 1,
        space: AppSpacing.lg,
      );

  static BottomNavigationBarThemeData _bottomNavTheme(
          {required bool isLight}) =>
      BottomNavigationBarThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainerLight
            : AppColors.surfaceContainerDark,
        selectedItemColor:
            isLight ? AppColors.primary : AppColors.primaryDarkMode,
        unselectedItemColor: isLight
            ? AppColors.textSecondaryLight
            : AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      );

  static NavigationRailThemeData _navigationRailTheme(
          {required bool isLight}) =>
      NavigationRailThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainerLight
            : AppColors.surfaceContainerDark,
        selectedIconTheme: IconThemeData(
          color: isLight ? AppColors.primary : AppColors.primaryDarkMode,
          size: AppIconSize.navBar,
        ),
        unselectedIconTheme: IconThemeData(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
          size: AppIconSize.navBar,
        ),
      );

  static ChipThemeData _chipTheme({required bool isLight}) => ChipThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainerLight
            : AppColors.surfaceContainerDark,
        selectedColor:
            isLight ? AppColors.primaryContainer : AppColors.primaryContainerDarkMode,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      );

  static DialogThemeData _dialogTheme({required bool isLight}) =>
      DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: isLight
            ? AppColors.surfaceContainerHighLight
            : AppColors.surfaceContainerHighDark,
      );

  static BottomSheetThemeData _bottomSheetTheme({required bool isLight}) =>
      BottomSheetThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainerLowLight
            : AppColors.surfaceContainerLowDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        showDragHandle: true,
      );
}
