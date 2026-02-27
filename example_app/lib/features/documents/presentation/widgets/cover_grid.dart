/// StarNote Cover Grid - Grid view for cover selection
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';

/// Cover grid widget
class CoverGridView extends StatelessWidget {
  final Cover selectedCover;
  final String title;
  final ValueChanged<Cover> onCoverSelected;

  const CoverGridView({
    super.key,
    required this.selectedCover,
    required this.title,
    required this.onCoverSelected,
  });

  @override
  Widget build(BuildContext context) {
    const covers = CoverRegistry.all;
    final isPhone = Responsive.isPhone(context);
    final crossAxisCount = isPhone ? 5 : 8;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.75,
      ),
      itemCount: covers.length,
      itemBuilder: (context, index) {
        final cover = covers[index];
        final isSelected = selectedCover.id == cover.id;

        return _CoverGridItem(
          cover: cover,
          isSelected: isSelected,
          title: title,
          onTap: () => onCoverSelected(cover),
        );
      },
    );
  }
}

class _CoverGridItem extends StatelessWidget {
  final Cover cover;
  final bool isSelected;
  final String title;
  final VoidCallback onTap;

  const _CoverGridItem({
    required this.cover,
    required this.isSelected,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected ? AppColors.primary : outlineColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverPreviewWidget(
                      cover: cover,
                      title: title.isEmpty ? 'Baslik' : title,
                      showBorder: false,
                    ),
                    // Premium badge
                    if (cover.isPremium)
                      Positioned(
                        top: AppSpacing.xs,
                        right: AppSpacing.xs,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.85),
                            borderRadius:
                                BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Icon(
                            Icons.lock,
                            size: AppIconSize.xs,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    // Selection indicator
                    if (isSelected)
                      Positioned(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: AppIconSize.xs,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            cover.name,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.primary : textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
