import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Horizontal strip of quick template thumbnails with a section title.
class AddPageTemplateSection extends StatelessWidget {
  const AddPageTemplateSection({
    super.key,
    required this.templates,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Template> templates;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              context.drawingStrings.templates.templatesHeader,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final t = templates[index];
                return QuickTemplateThumbnail(
                  template: t,
                  isSelected: t.id == selectedId,
                  onTap: () => onSelect(t.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// More templates, image, photo and import rows of the add-page panel.
class AddPageActionItems extends StatelessWidget {
  const AddPageActionItems({
    super.key,
    required this.onMoreTemplates,
    required this.onImage,
    required this.onCamera,
    required this.onImport,
  });

  final VoidCallback onMoreTemplates;
  final VoidCallback onImage;
  final VoidCallback onCamera;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = context.drawingStrings;
    final chevron = PhosphorIcon(
      ElyanotesIcons.chevronRight,
      size: 18,
      color: cs.onSurfaceVariant,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PageOptionsMenuItem(
          icon: ElyanotesIcons.template,
          label: s.pageList.moreTemplates,
          trailing: chevron,
          onTap: onMoreTemplates,
        ),
        PageOptionsMenuItem(
          icon: ElyanotesIcons.image,
          label: s.tools.image,
          trailing: chevron,
          onTap: onImage,
        ),
        PageOptionsMenuItem(
          icon: ElyanotesIcons.camera,
          label: s.pageList.takePhoto,
          trailing: chevron,
          onTap: onCamera,
        ),
        PageOptionsMenuItem(
          icon: ElyanotesIcons.uploadFile,
          label: s.pageList.importFile,
          trailing: chevron,
          onTap: onImport,
        ),
      ],
    );
  }
}
