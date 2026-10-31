/// ElyaNotes Template Grouped List - Collapsible tree view of all templates
library;

import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/presentation/l10n/library_labels.dart';
import 'package:example_app/features/documents/presentation/widgets/template_grid.dart';
import 'package:example_app/l10n/l10n.dart';

/// All templates grouped by category with collapsible sections.
class TemplateGroupedList extends StatefulWidget {
  final Template? selectedTemplate;
  final int paperColor;
  final ValueChanged<Template> onTemplateSelected;

  const TemplateGroupedList({
    super.key,
    this.selectedTemplate,
    required this.paperColor,
    required this.onTemplateSelected,
  });

  @override
  State<TemplateGroupedList> createState() => _TemplateGroupedListState();
}

class _TemplateGroupedListState extends State<TemplateGroupedList> {
  final Set<TemplateCategory> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    const categories = TemplateCategory.values;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final templates = TemplateRegistry.getByCategory(category);
        if (templates.isEmpty) return const SizedBox.shrink();

        final isCollapsed = _collapsed.contains(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryHeader(
              category: category,
              templateCount: templates.length,
              isExpanded: !isCollapsed,
              onToggle: () => setState(() {
                if (isCollapsed) {
                  _collapsed.remove(category);
                } else {
                  _collapsed.add(category);
                }
              }),
            ),
            if (!isCollapsed) _buildCategoryGrid(templates),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _buildCategoryGrid(List<Template> templates) {
    final isPhone = Responsive.isPhone(context);
    final crossAxisCount = isPhone ? 4 : 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.62,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = widget.selectedTemplate?.id == template.id;

        return TemplateGridItem(
          template: template,
          isSelected: isSelected,
          paperColor: widget.paperColor,
          onTap: () => widget.onTemplateSelected(template),
        );
      },
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final TemplateCategory category;
  final int templateCount;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _CategoryHeader({
    required this.category,
    required this.templateCount,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textMuted;
    final name = localizedName(
      l10n,
      tr: category.displayName,
      en: category.displayNameEn,
    );

    // One node per header: name and count are read together, the chevron is
    // decorative, and the expanded state is announced instead of only drawn.
    return Semantics(
      button: true,
      expanded: isExpanded,
      label: '$name, ${l10n.libraryTemplateCount(templateCount)}',
      excludeSemantics: true,
      onTap: onToggle,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Row(
            children: [
              AnimatedRotation(
                turns: isExpanded ? 0.0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  size: AppIconSize.sm,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                name,
                style: AppTypography.labelLarge.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '($templateCount)',
                style: AppTypography.caption.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
