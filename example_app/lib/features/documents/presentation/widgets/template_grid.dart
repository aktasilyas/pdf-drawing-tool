/// StarNote Template Grid - Grid view for template selection
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';

/// Template grid widget
class TemplateGridView extends StatelessWidget {
  final TemplateCategory category;
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
    final templates = TemplateRegistry.getByCategory(category);
    final isPhone = Responsive.isPhone(context);
    final crossAxisCount = isPhone ? 4 : 8;

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
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = selectedTemplate?.id == template.id;

        return _TemplateGridItem(
          template: template,
          isSelected: isSelected,
          paperColor: paperColor,
          onTap: () => onTemplateSelected(template),
        );
      },
    );
  }
}

class _TemplateGridItem extends StatelessWidget {
  final Template template;
  final bool isSelected;
  final int paperColor;
  final VoidCallback onTap;

  const _TemplateGridItem({
    required this.template,
    required this.isSelected,
    required this.paperColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outlineLight,
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
            template.name,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
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
