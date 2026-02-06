/// StarNote Documents Header - Başlık, sıralama ve görünüm modu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/selection_mode_header.dart';

class DocumentsHeader extends ConsumerWidget {
  final String title;
  final VoidCallback onNewPressed;
  final SortOption sortOption;
  final ValueChanged<SortOption> onSortChanged;
  final GlobalKey? newButtonKey;
  final List<String> allDocumentIds;
  final List<String> allFolderIds;
  final bool isTrashSection;
  final VoidCallback? onEmptyTrash;

  const DocumentsHeader({
    super.key,
    required this.title,
    required this.onNewPressed,
    required this.sortOption,
    required this.onSortChanged,
    this.newButtonKey,
    this.allDocumentIds = const [],
    this.allFolderIds = const [],
    this.isTrashSection = false,
    this.onEmptyTrash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPhone = Responsive.isPhone(context);
    final isSelectionMode = ref.watch(selectionModeProvider);

    if (isSelectionMode) {
      return SelectionModeHeader(
        allDocumentIds: allDocumentIds,
        allFolderIds: allFolderIds,
        isTrashSection: isTrashSection,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? AppSpacing.lg : AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(context, ref, isPhone),
          if (isTrashSection) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildTrashInfo(context),
          ],
          const SizedBox(height: AppSpacing.lg),
          _buildSearchField(ref),
        ],
      ),
    );
  }

  Widget _buildTrashInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: AppIconSize.sm,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Silinen notlar 30 gün sonra kalıcı olarak silinir',
              style: AppTypography.caption.copyWith(color: textSecondary),
            ),
          ),
          if (onEmptyTrash != null && allDocumentIds.isNotEmpty)
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

  Widget _buildHeaderRow(BuildContext context, WidgetRef ref, bool isPhone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewMode = ref.watch(viewModeProvider);
    final sortDirection = ref.watch(sortDirectionProvider);
    final pinFavorites = ref.watch(pinFavoritesProvider);
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      children: [
        // Title
        Expanded(
          child: Text(
            title,
            style: (isPhone
                    ? AppTypography.headlineMedium
                    : AppTypography.headlineLarge)
                .copyWith(color: textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Actions
        if (!isTrashSection)
          AppIconButton(
            key: newButtonKey,
            icon: Icons.add,
            variant: AppIconButtonVariant.filled,
            tooltip: 'Yeni Belge',
            onPressed: onNewPressed,
          ),
        const SizedBox(width: AppSpacing.xs),
        _SortPopupButton(
          sortOption: sortOption,
          sortDirection: sortDirection,
          pinFavorites: pinFavorites,
          onSortChanged: onSortChanged,
          onDirectionChanged: () {
            final newDir = sortDirection == SortDirection.descending
                ? SortDirection.ascending
                : SortDirection.descending;
            ref.read(sortDirectionProvider.notifier).set(newDir);
          },
          onPinFavoritesChanged: () {
            ref.read(pinFavoritesProvider.notifier).toggle();
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        AppIconButton(
          icon: viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
          variant: AppIconButtonVariant.ghost,
          tooltip:
              viewMode == ViewMode.grid ? 'Liste görünümü' : 'Grid görünümü',
          onPressed: () {
            final newMode =
                viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
            ref.read(viewModeProvider.notifier).set(newMode);
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        AppIconButton(
          icon: Icons.check_circle_outline,
          variant: AppIconButtonVariant.ghost,
          tooltip: 'Seçim modu',
          onPressed: () {
            ref.read(selectionModeProvider.notifier).state = true;
          },
        ),
        // Settings button (tablet only - phone has it in mobile header)
        if (!isPhone) ...[
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: Icons.settings_outlined,
            variant: AppIconButtonVariant.ghost,
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return AppSearchField(
      hint: 'Belgelerde ara...',
      onChanged: (query) {
        ref.read(searchQueryProvider.notifier).state = query;
      },
    );
  }
}

/// Sort popup button with options
class _SortPopupButton extends StatelessWidget {
  final SortOption sortOption;
  final SortDirection sortDirection;
  final bool pinFavorites;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onDirectionChanged;
  final VoidCallback onPinFavoritesChanged;

  const _SortPopupButton({
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
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, size: AppIconSize.lg, color: textSecondary),
      tooltip: 'Sıralama',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      onSelected: (value) {
        if (value == 'pin_favorites') {
          onPinFavoritesChanged();
        } else if (value == 'direction') {
          onDirectionChanged();
        } else {
          onSortChanged(SortOption.values.firstWhere((e) => e.name == value));
        }
      },
      itemBuilder: (context) => [
        _buildSortItem(
            context, 'date', 'Tarihe göre', sortOption == SortOption.date),
        _buildSortItem(
            context, 'name', 'İsme göre', sortOption == SortOption.name),
        _buildSortItem(
            context, 'size', 'Boyuta göre', sortOption == SortOption.size),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'direction',
          child: Row(
            children: [
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
                  style: AppTypography.bodyMedium.copyWith(color: textPrimary),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'pin_favorites',
          child: Row(
            children: [
              Icon(
                pinFavorites ? Icons.push_pin : Icons.push_pin_outlined,
                size: AppIconSize.md,
                color: pinFavorites ? AppColors.accent : textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Favorileri üste sabitle',
                  style: AppTypography.bodyMedium.copyWith(color: textPrimary),
                ),
              ),
              if (pinFavorites)
                const Icon(Icons.check,
                    size: AppIconSize.md, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildSortItem(
      BuildContext context, String value, String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
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
        ],
      ),
    );
  }
}
