import 'package:flutter/material.dart';

import 'package:example_app/core/theme/tokens/index.dart';

/// App bar, card, dialog, bottom sheet, popup menu and snack bar themes.
abstract final class AppSurfaceThemes {
  static AppBarTheme appBar({
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

  static CardThemeData card({required bool isLight}) => CardThemeData(
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

  static SnackBarThemeData snackBar({required bool isLight}) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? AppColors.inverseSurfaceLight
            : AppColors.inverseSurfaceDark,
        actionTextColor: isLight
            ? AppColors.inversePrimaryLight
            : AppColors.inversePrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  static PopupMenuThemeData popupMenu({required bool isLight}) =>
      PopupMenuThemeData(
        color: isLight
            ? AppColors.surfaceContainerLowLight
            : AppColors.surfaceContainerLowDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      );

  static DialogThemeData dialog({required bool isLight}) => DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: isLight
            ? AppColors.surfaceContainerHighLight
            : AppColors.surfaceContainerHighDark,
      );

  static BottomSheetThemeData bottomSheet({required bool isLight}) =>
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
