import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_card.dart';

/// Template grid - responsive (phone: 4 kolon, tablet: 6 kolon)
class TemplateGrid extends StatelessWidget {
  final List<Template> templates;
  final Template? selectedTemplate;
  final ValueChanged<Template> onTemplateSelected;
  final bool Function(Template)? isLocked;

  const TemplateGrid({
    super.key,
    required this.templates,
    this.selectedTemplate,
    required this.onTemplateSelected,
    this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final crossAxisCount = isTablet ? 6 : 4;
        const spacing = 8.0;
        final childAspectRatio = isTablet ? 0.7 : 0.68;

        return GridView.builder(
          padding: const EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            final locked = isLocked?.call(template) ?? template.isPremium;

            return TemplateCard(
              template: template,
              isSelected: selectedTemplate?.id == template.id,
              isLocked: locked,
              onTap: () => onTemplateSelected(template),
            );
          },
        );
      },
    );
  }
}
