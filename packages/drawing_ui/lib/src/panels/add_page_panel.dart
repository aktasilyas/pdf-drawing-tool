import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';

/// Quick-access template IDs shown in the horizontal thumbnail strip.
const _quickTemplateIds = ['blank', 'thin_lined', 'grid', 'dotted', 'cornell'];

/// GoodNotes-style "Add Page" popup panel.
///
/// Shows position selection, quick template thumbnails, and action items
/// (more templates, image, photo, import). UI-only for now — functionality
/// will be wired in a follow-up.
class AddPagePanel extends StatefulWidget {
  const AddPagePanel({super.key, required this.onClose, this.embedded = false});

  final VoidCallback onClose;

  /// When true, skips Material/SizedBox wrapper (used inside PopoverController).
  final bool embedded;

  @override
  State<AddPagePanel> createState() => _AddPagePanelState();
}

class _AddPagePanelState extends State<AddPagePanel> {
  AddPagePosition _selectedPosition = AddPagePosition.after;
  String _selectedTemplateId = 'blank';

  late final List<Template> _quickTemplates;

  @override
  void initState() {
    super.initState();
    _quickTemplates = _quickTemplateIds
        .map((id) => TemplateRegistry.getById(id))
        .whereType<Template>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(cs),
        _divider(cs),
        AddPagePositionSelector(
          selected: _selectedPosition,
          onChanged: (pos) => setState(() => _selectedPosition = pos),
        ),
        _divider(cs),
        _buildTemplateSection(cs),
        _divider(cs),
        _buildActionItems(cs),
        const SizedBox(height: 8),
      ],
    );

    if (widget.embedded) return content;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(width: 320, child: content),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sayfa ekle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: PhosphorIcon(
              StarNoteIcons.close,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            onPressed: widget.onClose,
            splashRadius: 20,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              'Şablonlar',
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
              itemCount: _quickTemplates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final t = _quickTemplates[index];
                return QuickTemplateThumbnail(
                  template: t,
                  isSelected: t.id == _selectedTemplateId,
                  onTap: () {
                    setState(() => _selectedTemplateId = t.id);
                    // Placeholder: just close for now
                    widget.onClose();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItems(ColorScheme cs) {
    final chevron = PhosphorIcon(
      StarNoteIcons.chevronRight,
      size: 18,
      color: cs.onSurfaceVariant,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PageOptionsMenuItem(
          icon: StarNoteIcons.template,
          label: 'Daha Fazla Şablon',
          trailing: chevron,
          onTap: widget.onClose,
        ),
        PageOptionsMenuItem(
          icon: StarNoteIcons.image,
          label: 'Resim',
          trailing: chevron,
          onTap: widget.onClose,
        ),
        PageOptionsMenuItem(
          icon: StarNoteIcons.camera,
          label: 'Fotoğraf çek',
          trailing: chevron,
          onTap: widget.onClose,
        ),
        PageOptionsMenuItem(
          icon: StarNoteIcons.uploadFile,
          label: 'İçe aktar',
          trailing: chevron,
          onTap: widget.onClose,
        ),
      ],
    );
  }

  Widget _divider(ColorScheme cs) =>
      Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant);
}
