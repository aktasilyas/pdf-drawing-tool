/// StarNote Template Preview Card - Preview card for template selection
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Preview card widget for template/cover selection
class TemplatePreviewCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double width;
  final double height;
  final Widget child;
  final VoidCallback? onTap;

  const TemplatePreviewCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.child,
    this.onTap,
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
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isSelected ? AppColors.primary : outlineColor,
                width: isSelected ? 2 : 1,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm - 1),
              child: child,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.primary : textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
