import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/panels/add_page_import_helper.dart';
import 'package:drawing_ui/src/panels/add_page_panel_sections.dart';
import 'package:drawing_ui/src/panels/add_page_panel_widgets.dart';
import 'package:drawing_ui/src/panels/page_structure_undo.dart';
import 'package:drawing_ui/src/services/image_page_import.dart';
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
  void _insertNewPage(
    PageBackground background, {
    required DrawingStrings strings,
    PageSize? size,
  }) {
    final doc = ref.read(documentProvider);
    final currentIndex = ref.read(currentPageIndexProvider);
    _insertPage(
      actions: ref.read(pageStructureActionsProvider),
      messenger: ScaffoldMessenger.maybeOf(context),
      strings: strings,
      index: _resolveInsertionIndex(currentIndex, doc.pages.length),
      size: size ?? doc.settings.defaultPageSize,
      background: background,
    );
  }

  /// Inserts the page through [actions] and offers undo. Uses no `ref` or
  /// `context`, so it also works after the popover has closed.
  static void _insertPage({
    required PageStructureActions actions,
    required ScaffoldMessengerState? messenger,
    required DrawingStrings strings,
    required int index,
    required PageSize size,
    required PageBackground background,
  }) {
    final page = Page.create(index: index, size: size, background: background);
    final change = actions.insertPage(index, page);
    showPageUndoSnackBar(
      messenger,
      actions,
      change,
      strings.pages.pageAdded,
      undoLabel: strings.toolbar.undo,
      undoFailedMessage: strings.pages.cannotUndo,
    );
  }

  void _addPageFromTemplate(String templateId) {
    final t = TemplateRegistry.getById(templateId);
    if (t == null) return;
    _insertNewPage(
      PageBackground.fromTemplate(t),
      strings: context.drawingStrings,
    );
    widget.onClose();
  }

  Future<void> _openTemplatePicker() async {
    // Capture refs before close — onClose unmounts the widget.
    final actions = ref.read(pageStructureActionsProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final doc = ref.read(documentProvider);
    final curIdx = ref.read(currentPageIndexProvider);
    final navCtx = Navigator.of(context, rootNavigator: true).context;
    final strings = context.drawingStrings;
    widget.onClose();
    final result = await TemplatePicker.show(navCtx);
    if (result == null) return;
    final t = result.template;
    _insertPage(
      actions: actions,
      messenger: messenger,
      strings: strings,
      index: _resolveInsertionIndex(curIdx, doc.pages.length),
      size: doc.settings.defaultPageSize,
      background: PageBackground.fromTemplate(
        t,
        color: result.backgroundColor?.toARGB32(),
        lineColor: result.lineColor?.toARGB32(),
      ),
    );
  }

  Future<void> _addImagePage(ImageSource source) async {
    final strings = context.drawingStrings;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final paths = ref.read(pdfPathResolverProvider);
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final image = await importImagePage(
        picked.path,
        documentsRoot: appDir.path,
        paths: paths,
      );
      if (!mounted) {
        await discardImportedImagePage(image, paths: paths);
        return;
      }
      _insertNewPage(image.background, strings: strings, size: image.size);
    } on ImagePageImportException {
      messenger?.showSnackBar(
        SnackBar(content: Text(strings.errors.imageReadFailed)),
      );
    }
    if (mounted) widget.onClose();
  }

  Future<void> _handleImport() async {
    // Capture before close — onClose unmounts the widget. The container
    // outlives it, so the latest document can be read after the import.
    final container = ProviderScope.containerOf(context, listen: false);
    final actions = ref.read(pageStructureActionsProvider);
    final importer = ref.read(pageFileImporterProvider);
    final doc = ref.read(documentProvider);
    final curIdx = ref.read(currentPageIndexProvider);
    final anchorId =
        curIdx >= 0 && curIdx < doc.pages.length ? doc.pages[curIdx].id : null;
    final insertIdx = _resolveInsertionIndex(curIdx, doc.pages.length);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final strings = context.drawingStrings;
    widget.onClose();

    final imported = await importer(
      insertIndex: insertIdx,
      defaultPageSize: doc.settings.defaultPageSize,
      pdfPaths: ref.read(pdfPathResolverProvider),
      onImageError: () => messenger?.showSnackBar(
        SnackBar(content: Text(strings.errors.imageReadFailed)),
      ),
      onError: (failure) => messenger?.showSnackBar(
        SnackBar(content: Text(failure.message(strings))),
      ),
      onPagesSkipped: (count) => messenger?.showSnackBar(
        SnackBar(content: Text(strings.errors.pdfPagesSkipped(count))),
      ),
    );
    if (imported.isEmpty) return;

    // The document may have changed while the import ran (ink, renames,
    // page changes): insert into its latest state, next to the same page.
    final fresh = container.read(documentProvider);
    final anchor = fresh.pages.indexWhere((p) => p.id == anchorId);
    final freshIdx =
        anchor >= 0 ? anchor : container.read(currentPageIndexProvider);
    final change = actions.insertPages(
      _resolveInsertionIndex(freshIdx, fresh.pages.length),
      imported,
    );
    showPageUndoSnackBar(
      messenger,
      actions,
      change,
      strings.pages.pageAdded,
      undoLabel: strings.toolbar.undo,
      undoFailedMessage: strings.pages.cannotUndo,
    );
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
                AddPageTemplateSection(
                  templates: _quickTemplates,
                  selectedId: _selectedTemplateId,
                  onSelect: _addPageFromTemplate,
                ),
                _divider(cs),
                AddPageActionItems(
                  onMoreTemplates: _openTemplatePicker,
                  onImage: () => _addImagePage(ImageSource.gallery),
                  onCamera: () => _addImagePage(ImageSource.camera),
                  onImport: _handleImport,
                ),
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
      shadowColor: cs.shadow.withValues(alpha: 0.26),
      child: SizedBox(width: 320, child: content),
    );
  }

  Widget _divider(ColorScheme cs) =>
      Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant);
}
