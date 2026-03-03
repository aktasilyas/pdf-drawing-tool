/// ElyaNotes Documents Header - Başlık, sıralama ve görünüm modu.
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
import 'sort_popup_button.dart';

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
          _buildTitleRow(context, isPhone),
          if (isTrashSection) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildTrashInfo(context),
          ],
          const SizedBox(height: AppSpacing.md),
          _buildActionRow(context, ref),
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, bool isPhone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      children: [
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
        if (!isPhone)
          _CircleIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/settings'),
          ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    final sortDirection = ref.watch(sortDirectionProvider);
    final pinFavorites = ref.watch(pinFavoritesProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isTrashSection)
          _CircleIconButton(
            key: newButtonKey,
            icon: Icons.add,
            tooltip: 'Yeni Belge',
            onPressed: onNewPressed,
          ),
        if (!isTrashSection) const SizedBox(width: AppSpacing.sm),
        SortPopupButton(
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
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(
          icon: viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
          tooltip:
              viewMode == ViewMode.grid ? 'Liste görünümü' : 'Grid görünümü',
          onPressed: () {
            final newMode =
                viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
            ref.read(viewModeProvider.notifier).set(newMode);
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(
          icon: Icons.check_circle_outline,
          tooltip: 'Seçim modu',
          onPressed: () {
            ref.read(selectionModeProvider.notifier).state = true;
          },
        ),
      ],
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
          const Icon(Icons.info_outline,
              size: AppIconSize.sm, color: AppColors.warning),
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
}

/// Circle-background icon button matching sidebar tile style.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;
    final bgColor = isDark
        ? AppColors.surfaceContainerHighDark
        : AppColors.surfaceContainerHighLight;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
