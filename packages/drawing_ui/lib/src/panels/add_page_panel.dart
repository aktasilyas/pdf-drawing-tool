import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';

/// Quick-access template IDs shown in the horizontal thumbnail strip.
const _quickTemplateIds = ['blank', 'thin_lined', 'grid', 'dotted', 'cornell'];

/// GoodNotes-style "Add Page" popup panel.
///
/// Shows position selection, quick template thumbnails, and action items
/// (more templates, image, photo, import). Tapping a template creates a new
/// page at the selected position using the document's default page size.
class AddPagePanel extends ConsumerStatefulWidget {
  const AddPagePanel({super.key, required this.onClose, this.embedded = false});

  final VoidCallback onClose;

  /// When true, skips Material/SizedBox wrapper (used inside PopoverController).
  final bool embedded;

  @override
  ConsumerState<AddPagePanel> createState() => _AddPagePanelState();
}

class _AddPagePanelState extends ConsumerState<AddPagePanel> {
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

  int _resolveInsertionIndex(int currentIndex, int pageCount) {
    switch (_selectedPosition) {
      case AddPagePosition.before:
        return currentIndex;
      case AddPagePosition.after:
        return currentIndex + 1;
      case AddPagePosition.lastPage:
        return pageCount;
    }
  }

  void _addPageFromTemplate(String templateId) {
    final template = TemplateRegistry.getById(templateId);
    if (template == null) return;

    final doc = ref.read(documentProvider);
    final currentIndex = ref.read(currentPageIndexProvider);

    final background = PageBackground(
      type: BackgroundType.template,
      color: template.defaultBackgroundColor,
      templatePattern: template.pattern,
      templateSpacingMm: template.spacingMm,
      templateLineWidth: template.lineWidth,
      lineColor: template.defaultLineColor,
    );

    final insertIndex = _resolveInsertionIndex(currentIndex, doc.pages.length);
    final newPage = Page.create(
      index: insertIndex,
      size: doc.settings.defaultPageSize,
      background: background,
    );

    final newPages = List<Page>.from(doc.pages)..insert(insertIndex, newPage);
    // Reindex pages after insertion
    for (int i = insertIndex; i < newPages.length; i++) {
      newPages[i] = newPages[i].copyWith(index: i);
    }

    final newDoc = doc.copyWith(
      pages: newPages,
      currentPageIndex: insertIndex,
    );
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
    widget.onClose();
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
                  onTap: () => _addPageFromTemplate(t.id),
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
