/// ElyaNotes Folder Card
///
/// Klasör kartı widget'ı. DocumentCard ile aynı boyut ve yapıda.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';

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
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardResting(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildThumbnailCard(context, ref)),
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.sm,
                left: AppSpacing.sm,
                right: AppSpacing.sm),
            child: _buildInfoSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailCard(BuildContext context, WidgetRef ref) {
    final folderColor = Color(folder.colorValue);

    return Stack(
      children: [
        // Klasör ikonu + tap gesture (altta, favori butonunun altında)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onLongPress: () => _handleLongPress(ref),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(Icons.folder_rounded, color: folderColor),
            ),
          ),
        ),
        // Belge sayısı (ikon üzerinde ortalanmış)
        if (folder.documentCount > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, 0.15),
                child: Text(
                  '${folder.documentCount}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        // Favori butonu - sağ üst (tap önceliği)
        if (!isSelectionMode)
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: _FavoriteButton(
              isFavorite: folder.isFavorite,
              onTap: () => ref
                  .read(foldersControllerProvider.notifier)
                  .toggleFavorite(folder.id),
            ),
          ),
        // Selection checkbox
        if (isSelectionMode)
          Positioned(
            top: 0,
            left: 0,
            child: _SelectionCheckbox(
              isSelected: isSelected,
            ),
          ),
      ],
    );
  }

  void _handleLongPress(WidgetRef ref) {
    if (!isSelectionMode) {
      ref.read(selectionModeProvider.notifier).state = true;
      ref.read(selectedFoldersProvider.notifier).state = {folder.id};
    }
  }

  Widget _buildInfoSection(BuildContext context) {
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textMuted;
    final textTertiary = context.palette.textDisabled;

    return GestureDetector(
      onTap: onMorePressed,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  style: AppTypography.titleMedium.copyWith(color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${folder.documentCount} belge',
                  style: AppTypography.caption.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          if (onMorePressed != null && !isSelectionMode)
            Icon(
              Icons.keyboard_arrow_down,
              key: const Key('folder_card_more_button'),
              size: AppIconSize.md,
              color: textTertiary,
            ),
        ],
      ),
    );
  }
}

/// Favorite button widget - DocumentFavoriteButton ile aynı pattern
class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: (context.palette.surface).withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.star : Icons.star_outline,
              size: AppIconSize.sm,
              color: isFavorite
                  ? AppColors.accent
                  : (context.palette.textDisabled),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selection checkbox widget
class _SelectionCheckbox extends StatelessWidget {
  final bool isSelected;

  const _SelectionCheckbox({
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = context.palette.accent;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? accentColor : (context.palette.surface),
        border: Border.all(
          color: isSelected ? accentColor : (context.palette.border),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
          : null,
    );
  }
}
