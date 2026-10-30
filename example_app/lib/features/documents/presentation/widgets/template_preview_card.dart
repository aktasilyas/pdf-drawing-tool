/// ElyaNotes Template Preview Card - Preview card for template selection
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
    final outlineColor = context.palette.border;
    final textSecondary = context.palette.textMuted;
    final accent = context.palette.accent;

    final card = GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isSelected ? accent : outlineColor,
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
              color: isSelected ? accent : textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );

    // Read as one selectable button; the preview inside is decorative.
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: card,
    );
  }
}
