/// ElyaNotes Sort Popup Button - Circle-style sort menu
library;

import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';

/// Sort popup button with circle background matching sidebar style.
class SortPopupButton extends StatelessWidget {
  final SortOption sortOption;
  final SortDirection sortDirection;
  final bool pinFavorites;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onDirectionChanged;
  final VoidCallback onPinFavoritesChanged;

  const SortPopupButton({
    super.key,
    required this.sortOption,
    required this.sortDirection,
    required this.pinFavorites,
    required this.onSortChanged,
    required this.onDirectionChanged,
    required this.onPinFavoritesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;
    final bgColor = isDark
        ? AppColors.surfaceContainerHighDark
        : AppColors.surfaceContainerHighLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      child: SizedBox(
        width: 36,
        height: 36,
        child: PopupMenuButton<String>(
          icon: Icon(Icons.sort, size: 20, color: iconColor),
          tooltip: 'Sıralama',
          padding: EdgeInsets.zero,
          iconSize: 20,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          onSelected: (value) {
            if (value == 'pin_favorites') {
              onPinFavoritesChanged();
            } else if (value == 'direction') {
              onDirectionChanged();
            } else {
              onSortChanged(
                  SortOption.values.firstWhere((e) => e.name == value));
            }
          },
          itemBuilder: (context) => [
            _sortItem(context, 'date', 'Tarihe göre',
                sortOption == SortOption.date),
            _sortItem(context, 'name', 'İsme göre',
                sortOption == SortOption.name),
            _sortItem(context, 'size', 'Boyuta göre',
                sortOption == SortOption.size),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'direction',
              child: Row(children: [
                Icon(
                  sortDirection == SortDirection.descending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: AppIconSize.md,
                  color: textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    sortDirection == SortDirection.descending
                        ? 'Yeniden eskiye'
                        : 'Eskiden yeniye',
                    style:
                        AppTypography.bodyMedium.copyWith(color: textPrimary),
                  ),
                ),
              ]),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'pin_favorites',
              child: Row(children: [
                Icon(
                  pinFavorites ? Icons.push_pin : Icons.push_pin_outlined,
                  size: AppIconSize.md,
                  color: pinFavorites ? AppColors.accent : textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Favorileri üste sabitle',
                      style: AppTypography.bodyMedium
                          .copyWith(color: textPrimary)),
                ),
                if (pinFavorites)
                  const Icon(Icons.check,
                      size: AppIconSize.md, color: AppColors.primary),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
      BuildContext context, String value, String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return PopupMenuItem(
      value: value,
      child: Row(children: [
        SizedBox(
          width: AppIconSize.md,
          child: isSelected
              ? const Icon(Icons.check,
                  size: AppIconSize.md, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Text(label,
            style: AppTypography.bodyMedium.copyWith(color: textPrimary)),
      ]),
    );
  }
}
