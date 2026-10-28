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
import 'package:example_app/core/theme/app_color_schemes.dart';
import 'package:example_app/core/theme/components/button_themes.dart';
import 'package:example_app/core/theme/components/input_themes.dart';
import 'package:example_app/core/theme/components/navigation_themes.dart';
import 'package:example_app/core/theme/components/surface_themes.dart';
import 'package:example_app/core/theme/tokens/index.dart';

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
    final colorScheme = AppColorSchemes.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      extensions: [AppPalette.light, AppPalette.light.chrome],
      textTheme: AppTypography.create(Brightness.light),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.surfaceLight,
      dividerColor: AppColors.outlineLight,
      appBarTheme:
          AppSurfaceThemes.appBar(colorScheme: colorScheme, isLight: true),
      cardTheme: AppSurfaceThemes.card(isLight: true),
      elevatedButtonTheme: AppButtonThemes.elevated(),
      outlinedButtonTheme: AppButtonThemes.outlined(),
      textButtonTheme: AppButtonThemes.text(),
      inputDecorationTheme: AppInputThemes.inputDecoration(
        colorScheme: colorScheme,
        isLight: true,
      ),
      floatingActionButtonTheme: AppInputThemes.fab(colorScheme: colorScheme),
      snackBarTheme: AppSurfaceThemes.snackBar(isLight: true),
      dividerTheme: AppNavigationThemes.divider(isLight: true),
      bottomNavigationBarTheme: AppNavigationThemes.bottomNav(isLight: true),
      navigationRailTheme: AppNavigationThemes.navigationRail(isLight: true),
      chipTheme: AppNavigationThemes.chip(isLight: true),
      dialogTheme: AppSurfaceThemes.dialog(isLight: true),
      bottomSheetTheme: AppSurfaceThemes.bottomSheet(isLight: true),
      popupMenuTheme: AppSurfaceThemes.popupMenu(isLight: true),
      iconTheme: AppNavigationThemes.icon(isLight: true),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════

  /// Dark tema
  static ThemeData get dark {
    final colorScheme = AppColorSchemes.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      extensions: [AppPalette.dark, AppPalette.dark.chrome],
      textTheme: AppTypography.create(Brightness.dark),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.outlineDark,
      appBarTheme:
          AppSurfaceThemes.appBar(colorScheme: colorScheme, isLight: false),
      cardTheme: AppSurfaceThemes.card(isLight: false),
      elevatedButtonTheme: AppButtonThemes.elevated(),
      outlinedButtonTheme: AppButtonThemes.outlined(),
      textButtonTheme: AppButtonThemes.text(),
      inputDecorationTheme: AppInputThemes.inputDecoration(
        colorScheme: colorScheme,
        isLight: false,
      ),
      floatingActionButtonTheme: AppInputThemes.fab(colorScheme: colorScheme),
      snackBarTheme: AppSurfaceThemes.snackBar(isLight: false),
      dividerTheme: AppNavigationThemes.divider(isLight: false),
      bottomNavigationBarTheme: AppNavigationThemes.bottomNav(isLight: false),
      navigationRailTheme: AppNavigationThemes.navigationRail(isLight: false),
      chipTheme: AppNavigationThemes.chip(isLight: false),
      dialogTheme: AppSurfaceThemes.dialog(isLight: false),
      bottomSheetTheme: AppSurfaceThemes.bottomSheet(isLight: false),
      popupMenuTheme: AppSurfaceThemes.popupMenu(isLight: false),
      iconTheme: AppNavigationThemes.icon(isLight: false),
    );
  }
}
