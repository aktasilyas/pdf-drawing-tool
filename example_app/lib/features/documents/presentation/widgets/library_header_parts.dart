/// Building blocks of the library header (search, view actions, new button,
/// trash info strip).
library;

import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/constants/documents_strings.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/sort_popup_button.dart';

/// Search field bound to [searchQueryProvider].
class LibrarySearchField extends ConsumerWidget {
  const LibrarySearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSearchField(
      hint: DocumentsStrings.search,
      text: ref.watch(searchQueryProvider),
      onChanged: (value) =>
          ref.read(searchQueryProvider.notifier).state = value,
    );
  }
}

/// Sort, view-mode toggle and select actions (ghost, 48 hit, 20 icon).
class LibraryViewActions extends ConsumerWidget {
  const LibraryViewActions({
    super.key,
    required this.sortOption,
    required this.onSortChanged,
  });

  final SortOption sortOption;
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    final sortDirection = ref.watch(sortDirectionProvider);
    final pinFavorites = ref.watch(pinFavoritesProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SortPopupButton(
          sortOption: sortOption,
          sortDirection: sortDirection,
          pinFavorites: pinFavorites,
          onSortChanged: onSortChanged,
          onDirectionChanged: () {
            ref.read(sortDirectionProvider.notifier).set(
                  sortDirection == SortDirection.descending
                      ? SortDirection.ascending
                      : SortDirection.descending,
                );
          },
          onPinFavoritesChanged: () =>
              ref.read(pinFavoritesProvider.notifier).toggle(),
        ),
        AppIconButton(
          icon: viewMode == ViewMode.grid
              ? ElyanotesIcons.libraryRows
              : ElyanotesIcons.libraryGrid,
          variant: AppIconButtonVariant.ghost,
          size: AppIconButtonSize.small,
          tooltip:
              viewMode == ViewMode.grid ? 'Liste görünümü' : 'Grid görünümü',
          onPressed: () {
            ref.read(viewModeProvider.notifier).set(
                  viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
                );
          },
        ),
        AppIconButton(
          icon: ElyanotesIcons.librarySelect,
          variant: AppIconButtonVariant.ghost,
          size: AppIconButtonSize.small,
          tooltip: 'Seçim modu',
          onPressed: () =>
              ref.read(selectionModeProvider.notifier).state = true,
        ),
      ],
    );
  }
}

/// "Yeni" button; an icon-only filled button when [compact].
class LibraryNewButton extends StatelessWidget {
  const LibraryNewButton({
    super.key,
    required this.compact,
    required this.isLocked,
    required this.onPressed,
  });

  final bool compact;
  final bool isLocked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = isLocked ? 'Belge limiti doldu' : 'Yeni Belge';
    final icon =
        isLocked ? ElyanotesIcons.libraryLock : ElyanotesIcons.libraryPlus;

    if (compact) {
      return AppIconButton(
        icon: icon,
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
    return Tooltip(
      message: tooltip,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: AppButton(
          label: 'Yeni',
          leadingIcon: icon,
          trailingIcon: ElyanotesIcons.libraryCaretDown,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Info strip shown above the trash content.
class LibraryTrashInfo extends StatelessWidget {
  const LibraryTrashInfo({super.key, this.onEmptyTrash});

  /// Null hides the "Çöpü Boşalt" action.
  final VoidCallback? onEmptyTrash;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(ElyanotesIcons.libraryInfo,
              size: AppIconSize.sm, color: palette.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Silinen notlar 30 gün sonra kalıcı olarak silinir',
              style: AppTypography.caption.copyWith(color: palette.textMuted),
            ),
          ),
          if (onEmptyTrash != null)
            AppButton(
              label: 'Çöpü Boşalt',
              variant: AppButtonVariant.destructive,
              size: AppButtonSize.small,
              onPressed: onEmptyTrash,
            ),
        ],
      ),
    );
  }
}
