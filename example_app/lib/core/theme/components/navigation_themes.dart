import 'package:flutter/material.dart';

import 'package:example_app/core/theme/tokens/index.dart';

/// Icon, divider, navigation and chip themes.
abstract final class AppNavigationThemes {
  static IconThemeData icon({required bool isLight}) => IconThemeData(
        color: isLight
            ? AppColors.textSecondaryLight
            : AppColors.textSecondaryDark,
        size: AppIconSize.lg,
      );

  static DividerThemeData divider({required bool isLight}) => DividerThemeData(
        color: isLight
            ? AppColors.outlineVariantLight
            : AppColors.outlineVariantDark,
        thickness: 1,
        space: AppSpacing.lg,
      );

  static BottomNavigationBarThemeData bottomNav({required bool isLight}) =>
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

  static NavigationRailThemeData navigationRail({required bool isLight}) =>
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

  static ChipThemeData chip({required bool isLight}) => ChipThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceContainerLight
            : AppColors.surfaceContainerDark,
        selectedColor: isLight
            ? AppColors.primaryContainer
            : AppColors.primaryContainerDarkMode,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      );
}
