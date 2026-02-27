/// StarNote Template Grid - Grid view for template selection
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grouped_list.dart';

/// Template grid — shows single category grid or grouped "all" tree.
class TemplateGridView extends StatelessWidget {
  final TemplateCategory? category;
  final Template? selectedTemplate;
  final int paperColor;
  final ValueChanged<Template> onTemplateSelected;

  const TemplateGridView({
    super.key,
    required this.category,
    this.selectedTemplate,
    required this.paperColor,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      return TemplateGroupedList(
        selectedTemplate: selectedTemplate,
        paperColor: paperColor,
        onTemplateSelected: onTemplateSelected,
      );
    }

    final templates = TemplateRegistry.getByCategory(category!);
    final isPhone = Responsive.isPhone(context);
    final crossAxisCount = isPhone ? 4 : 7;

    if (templates.isEmpty) {
      return _buildEmpty(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.62,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = selectedTemplate?.id == template.id;

        return TemplateGridItem(
          template: template,
          isSelected: isSelected,
          paperColor: paperColor,
          onTap: () => onTemplateSelected(template),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 48,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bu kategoride sablon yok',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single template card used in both flat grid and grouped list.
class TemplateGridItem extends StatelessWidget {
  final Template template;
  final bool isSelected;
  final int paperColor;
  final VoidCallback onTap;

  const TemplateGridItem({
    super.key,
    required this.template,
    required this.isSelected,
    required this.paperColor,
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
                  children: [
                    TemplatePreviewWidget(
                      template: template,
                      backgroundColorOverride: Color(paperColor),
                      showBorder: false,
                    ),
                    if (template.isPremium)
                      Positioned(
                        top: AppSpacing.xxs,
                        right: AppSpacing.xxs,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            size: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (isSelected)
                      Positioned(
                        left: AppSpacing.xs,
                        bottom: AppSpacing.xs,
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
          const SizedBox(height: AppSpacing.xxs),
          Text(
            template.name,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.primary : textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 10,
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
