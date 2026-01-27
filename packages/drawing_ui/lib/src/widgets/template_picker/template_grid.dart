import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_card.dart';

/// Template grid - responsive (phone: 3 kolon, tablet: 5 kolon)
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
        final crossAxisCount = isTablet ? 5 : 3;
        final spacing = isTablet ? 16.0 : 12.0;
        final childAspectRatio = isTablet ? 0.75 : 0.72;

        return GridView.builder(
          padding: EdgeInsets.all(spacing),
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
