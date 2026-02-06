/// StarNote Folder Card
///
/// Klasör kartı widget'ı. AppCard (filled variant) kullanır.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

class FolderCard extends ConsumerWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;
  final bool isSelected;
  final bool isSelectionMode;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onMorePressed,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      variant: AppCardVariant.filled,
      isSelected: isSelected,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      onLongPress: () {
        if (!isSelectionMode) {
          ref.read(selectionModeProvider.notifier).state = true;
          ref.read(selectedFoldersProvider.notifier).state = {folder.id};
        }
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Folder icon and more button
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    size: AppIconSize.xxl,
                    color: Color(folder.colorValue),
                  ),
                  const Spacer(),
                  if (!isSelectionMode && onMorePressed != null)
                    AppIconButton(
                      icon: Icons.more_vert,
                      variant: AppIconButtonVariant.ghost,
                      size: AppIconButtonSize.small,
                      tooltip: 'Daha fazla',
                      onPressed: onMorePressed,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Folder name
              Flexible(
                child: Text(
                  folder.name,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Document count
              Text(
                '${folder.documentCount} belge',
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          // Selection checkbox
          if (isSelectionMode)
            Positioned(
              top: 0,
              right: 0,
              child: _SelectionCheckbox(
                isSelected: isSelected,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }
}

/// Selection checkbox widget
class _SelectionCheckbox extends StatelessWidget {
  final bool isSelected;
  final bool isDark;

  const _SelectionCheckbox({
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
          : null,
    );
  }
}
