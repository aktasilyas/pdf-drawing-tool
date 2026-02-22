import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/panels/add_page_import_helper.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_picker.dart';

/// Quick-access template IDs shown in the horizontal thumbnail strip.
const _quickTemplateIds = ['blank', 'thin_lined', 'grid', 'dotted', 'cornell'];

/// GoodNotes-style "Add Page" popup panel.
///
/// Shows position selection, quick template thumbnails, and action items
/// (more templates, image, photo, import). Tapping a template creates a new
/// page at the selected position using the document's default page size.
class AddPagePanel extends ConsumerStatefulWidget {
  const AddPagePanel({
    super.key,
    required this.onClose,
    this.embedded = false,
  });

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

  int _resolveInsertionIndex(int currentIndex, int pageCount) =>
      switch (_selectedPosition) {
        AddPagePosition.before => currentIndex,
        AddPagePosition.after => currentIndex + 1,
        AddPagePosition.lastPage => pageCount,
      };

  /// Inserts a new page with the given background at the selected position.
  void _insertNewPage(PageBackground background, {PageSize? size}) {
    final doc = ref.read(documentProvider);
    final currentIndex = ref.read(currentPageIndexProvider);
    final insertIndex = _resolveInsertionIndex(currentIndex, doc.pages.length);
    final newPage = Page.create(
      index: insertIndex,
      size: size ?? doc.settings.defaultPageSize,
      background: background,
    );
    final newPages = List<Page>.from(doc.pages)..insert(insertIndex, newPage);
    for (int i = insertIndex; i < newPages.length; i++) {
      newPages[i] = newPages[i].copyWith(index: i);
    }
    final newDoc = doc.copyWith(
        pages: newPages, currentPageIndex: insertIndex);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
        newDoc.pages, currentIndex: newDoc.currentPageIndex);
  }

  void _addPageFromTemplate(String templateId) {
    final t = TemplateRegistry.getById(templateId);
    if (t == null) return;
    _insertNewPage(PageBackground(
      type: BackgroundType.template,
      color: t.defaultBackgroundColor,
      templatePattern: t.pattern,
      templateSpacingMm: t.spacingMm,
      templateLineWidth: t.lineWidth,
      lineColor: t.defaultLineColor,
    ));
    widget.onClose();
  }

  Future<void> _openTemplatePicker() async {
    // Capture refs before close — onClose unmounts the widget.
    final docNotifier = ref.read(documentProvider.notifier);
    final pageManager = ref.read(pageManagerProvider.notifier);
    final doc = ref.read(documentProvider);
    final curIdx = ref.read(currentPageIndexProvider);
    final navCtx = Navigator.of(context, rootNavigator: true).context;
    widget.onClose();
    final result = await TemplatePicker.show(navCtx);
    if (result == null) return;
    final t = result.template;
    final bg = PageBackground(
      type: BackgroundType.template,
      color: result.backgroundColor?.toARGB32() ?? t.defaultBackgroundColor,
      templatePattern: t.pattern, templateSpacingMm: t.spacingMm,
      templateLineWidth: t.lineWidth,
      lineColor: result.lineColor?.toARGB32() ?? t.defaultLineColor,
    );
    final idx = _resolveInsertionIndex(curIdx, doc.pages.length);
    final np = List<Page>.from(doc.pages)
      ..insert(idx, Page.create(
          index: idx, size: doc.settings.defaultPageSize, background: bg));
    for (int i = idx; i < np.length; i++) np[i] = np[i].copyWith(index: i);
    final nd = doc.copyWith(pages: np, currentPageIndex: idx);
    docNotifier.updateDocument(nd);
    pageManager.initializeFromDocument(nd.pages, currentIndex: idx);
  }

  Future<void> _addImagePage(ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/starnote_images');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final dest = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}'
        '.${picked.path.split('.').last}';
    await File(picked.path).copy(dest);
    final bytes = await File(dest).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _insertNewPage(
      PageBackground(type: BackgroundType.pdf, pdfData: bytes, pdfPageIndex: 1),
      size: PageSize(
          width: frame.image.width.toDouble(),
          height: frame.image.height.toDouble()),
    );
    if (mounted) widget.onClose();
  }

  Future<void> _handleImport() async {
    final docNotifier = ref.read(documentProvider.notifier);
    final pageManager = ref.read(pageManagerProvider.notifier);
    final doc = ref.read(documentProvider);
    final curIdx = ref.read(currentPageIndexProvider);
    final insertIdx = _resolveInsertionIndex(curIdx, doc.pages.length);
    widget.onClose();

    final imported = await pickAndImportFile(
      insertIndex: insertIdx,
      defaultPageSize: doc.settings.defaultPageSize,
    );
    if (imported.isEmpty) return;

    final newPages = List<Page>.from(doc.pages)..insertAll(insertIdx, imported);
    for (int i = insertIdx; i < newPages.length; i++) {
      newPages[i] = newPages[i].copyWith(index: i);
    }
    final newDoc = doc.copyWith(pages: newPages, currentPageIndex: insertIdx);
    docNotifier.updateDocument(newDoc);
    pageManager.initializeFromDocument(newDoc.pages, currentIndex: insertIdx);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddPageHeader(onClose: widget.onClose),
        _divider(cs),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            ),
          ),
        ),
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
          onTap: _openTemplatePicker,
        ),
        PageOptionsMenuItem(
          icon: StarNoteIcons.image,
          label: 'Resim',
          trailing: chevron,
          onTap: () => _addImagePage(ImageSource.gallery),
        ),
        PageOptionsMenuItem(
          icon: StarNoteIcons.camera,
          label: 'Fotoğraf çek',
          trailing: chevron,
          onTap: () => _addImagePage(ImageSource.camera),
        ),
        PageOptionsMenuItem(
          icon: StarNoteIcons.uploadFile,
          label: 'İçe aktar',
          trailing: chevron,
          onTap: _handleImport,
        ),
      ],
    );
  }

  Widget _divider(ColorScheme cs) =>
      Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant);
}
