/// ElyaNotes Sort Popup Button - ghost trigger with a palette-styled menu.
library;

import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/l10n/library_labels.dart';
import 'package:example_app/l10n/l10n.dart';

/// Sort button: a ghost icon button that opens the sort menu.
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
    return AppIconButton(
      icon: ElyanotesIcons.librarySort,
      variant: AppIconButtonVariant.ghost,
      size: AppIconButtonSize.small,
      tooltip: context.l10n.librarySortTitle,
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final palette = context.palette;
    final l10n = context.l10n;
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final value = await showMenu<String>(
      context: context,
      position: position,
      color: palette.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: palette.border),
      ),
      items: [
        for (final option in SortOption.values)
          _sortItem(
            context,
            option.name,
            option.label(l10n),
            sortOption == option,
          ),
        const PopupMenuDivider(),
        _toggleItem(
          context,
          'direction',
          sortDirection == SortDirection.descending
              ? l10n.librarySortNewestFirst
              : l10n.librarySortOldestFirst,
          icon: sortDirection == SortDirection.descending
              ? Icons.arrow_downward
              : Icons.arrow_upward,
          iconColor: palette.textMuted,
        ),
        const PopupMenuDivider(),
        _toggleItem(
          context,
          'pin_favorites',
          l10n.settingsPinFavorites,
          icon: pinFavorites ? Icons.push_pin : Icons.push_pin_outlined,
          iconColor: pinFavorites ? palette.accent : palette.textMuted,
          checked: pinFavorites,
        ),
      ],
    );
    if (value == null) return;
    if (value == 'pin_favorites') {
      onPinFavoritesChanged();
    } else if (value == 'direction') {
      onDirectionChanged();
    } else {
      onSortChanged(SortOption.values.firstWhere((e) => e.name == value));
    }
  }

  PopupMenuItem<String> _toggleItem(
    BuildContext context,
    String value,
    String label, {
    required IconData icon,
    required Color iconColor,
    bool checked = false,
  }) {
    final palette = context.palette;
    return PopupMenuItem<String>(
      value: value,
      height: AppSpacing.minTouchTarget,
      child: Row(children: [
        Icon(icon, size: AppIconSize.md, color: iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style:
                AppTypography.labelLarge.copyWith(color: palette.textPrimary),
          ),
        ),
        if (checked)
          Icon(ElyanotesIcons.libraryCheck,
              size: AppIconSize.md, color: palette.accent),
      ]),
    );
  }

  PopupMenuItem<String> _sortItem(
    BuildContext context,
    String value,
    String label,
    bool isSelected,
  ) {
    final palette = context.palette;
    return PopupMenuItem<String>(
      value: value,
      height: AppSpacing.minTouchTarget,
      child: Row(children: [
        Expanded(
          child: Text(
            label,
            style:
                AppTypography.labelLarge.copyWith(color: palette.textPrimary),
          ),
        ),
        if (isSelected)
          Icon(ElyanotesIcons.libraryCheck,
              size: AppIconSize.md, color: palette.accent),
      ]),
    );
  }
}
