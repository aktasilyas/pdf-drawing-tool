/// StarNote Design System - Theme Configuration
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

/// StarNote tema tanımları.
///
/// Light ve Dark temalar için ThemeData sağlar.
/// Hardcoded değer kullanımı yasaktır!
abstract class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════

  /// Light tema
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        textTheme: _textTheme(
          primary: AppColors.textPrimaryLight,
          secondary: AppColors.textSecondaryLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: AppColors.surfaceLight,
        dividerColor: AppColors.outlineLight,
        appBarTheme: _appBarTheme(isLight: true),
        cardTheme: _cardTheme(isLight: true),
        elevatedButtonTheme: _elevatedButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(isLight: true),
        textButtonTheme: _textButtonTheme(),
        inputDecorationTheme: _inputDecorationTheme(isLight: true),
        floatingActionButtonTheme: _fabTheme(),
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

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════

  /// Dark tema
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        textTheme: _textTheme(
          primary: AppColors.textPrimaryDark,
          secondary: AppColors.textSecondaryDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.surfaceDark,
        dividerColor: AppColors.outlineDark,
        appBarTheme: _appBarTheme(isLight: false),
        cardTheme: _cardTheme(isLight: false),
        elevatedButtonTheme: _elevatedButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(isLight: false),
        textButtonTheme: _textButtonTheme(),
        inputDecorationTheme: _inputDecorationTheme(isLight: false),
        floatingActionButtonTheme: _fabTheme(),
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

  // ══════════════════════════════════════════════════════════════════════════
  // COLOR SCHEMES
  // ══════════════════════════════════════════════════════════════════════════

  static ColorScheme get _lightColorScheme => const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.accent,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.surfaceVariantLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        error: AppColors.error,
        onError: AppColors.onError,
        outline: AppColors.outlineLight,
        outlineVariant: AppColors.outlineVariantLight,
      );

  static ColorScheme get _darkColorScheme => const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.surfaceVariantDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        error: AppColors.error,
        onError: AppColors.onError,
        outline: AppColors.outlineDark,
        outlineVariant: AppColors.outlineVariantDark,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static TextTheme _textTheme({
    required Color primary,
    required Color secondary,
  }) =>
      TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: primary),
        displayMedium: AppTypography.displayMedium.copyWith(color: primary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: primary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: primary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: primary),
        titleLarge: AppTypography.titleLarge.copyWith(color: primary),
        titleMedium: AppTypography.titleMedium.copyWith(color: primary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: primary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: primary),
        labelLarge: AppTypography.labelLarge.copyWith(color: primary),
        labelMedium: AppTypography.labelMedium.copyWith(color: secondary),
        bodySmall: AppTypography.caption.copyWith(color: secondary),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // COMPONENT THEMES
  // ══════════════════════════════════════════════════════════════════════════

  static AppBarTheme _appBarTheme({required bool isLight}) => AppBarTheme(
        backgroundColor:
            isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        foregroundColor:
            isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color:
              isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        ),
      );

  static CardThemeData _cardTheme({required bool isLight}) => CardThemeData(
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: isLight ? AppColors.outlineLight : AppColors.outlineDark,
          ),
        ),
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
          textStyle: AppTypography.labelLarge,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(
          {required bool isLight}) =>
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
          textStyle: AppTypography.labelLarge,
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
          textStyle: AppTypography.labelLarge,
        ),
      );

  /// Modern input decoration theme
  /// Default: border yok, sadece fill color
  /// Focus: 1.5px primary border
  static InputDecorationTheme _inputDecorationTheme({required bool isLight}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.surfaceVariantLight
            : AppColors.surfaceVariantDark,
        // Default: border yok (modern minimal)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide.none,
        ),
        // Enabled: border yok
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide.none,
        ),
        // Focus: 1.5px primary border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        // Error states
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14, // 14dp vertical padding
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isLight
              ? AppColors.textTertiaryLight
              : AppColors.textTertiaryDark,
        ),
        labelStyle: AppTypography.caption.copyWith(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
      );

  static FloatingActionButtonThemeData _fabTheme() =>
      const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        shape: CircleBorder(),
      );

  static SnackBarThemeData _snackBarTheme({required bool isLight}) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isLight ? AppColors.textPrimaryLight : AppColors.surfaceVariantDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isLight ? AppColors.surfaceLight : AppColors.textPrimaryDark,
        ),
        actionTextColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  static PopupMenuThemeData _popupMenuTheme({required bool isLight}) =>
      PopupMenuThemeData(
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          color:
              isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
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
        color: isLight ? AppColors.outlineLight : AppColors.outlineDark,
        thickness: 1,
        space: AppSpacing.lg,
      );

  static BottomNavigationBarThemeData _bottomNavTheme(
          {required bool isLight}) =>
      BottomNavigationBarThemeData(
        backgroundColor:
            isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isLight
            ? AppColors.textSecondaryLight
            : AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.labelMedium,
      );

  static NavigationRailThemeData _navigationRailTheme(
          {required bool isLight}) =>
      NavigationRailThemeData(
        backgroundColor:
            isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: AppIconSize.navBar,
        ),
        unselectedIconTheme: IconThemeData(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
          size: AppIconSize.navBar,
        ),
        selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
        ),
        unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
        ),
      );

  static ChipThemeData _chipTheme({required bool isLight}) => ChipThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceVariantLight
            : AppColors.surfaceVariantDark,
        selectedColor: AppColors.primary,
        disabledColor: isLight
            ? AppColors.surfaceVariantLight.withValues(alpha: 0.5)
            : AppColors.surfaceVariantDark.withValues(alpha: 0.5),
        labelStyle: AppTypography.labelMedium.copyWith(
          color:
              isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onPrimary,
        ),
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
        backgroundColor:
            isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color:
              isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isLight
              ? AppColors.textSecondaryLight
              : AppColors.textSecondaryDark,
        ),
      );

  static BottomSheetThemeData _bottomSheetTheme({required bool isLight}) =>
      BottomSheetThemeData(
        backgroundColor:
            isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
        ),
        dragHandleColor: isLight
            ? AppColors.outlineVariantLight
            : AppColors.outlineVariantDark,
        dragHandleSize: const Size(AppSpacing.xxl, AppSpacing.xs),
      );
}
