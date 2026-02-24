import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_picker.dart';

import 'export_panel.dart' show performPagesPDFExport;
import 'page_options_widgets.dart';
import 'toolbar_settings_panel.dart';

/// GoodNotes-style page options popup panel.
class PageOptionsPanel extends ConsumerStatefulWidget {
  const PageOptionsPanel({
    super.key,
    required this.onClose,
    this.embedded = false,
    this.pageIndex,
  });

  final VoidCallback onClose;

  /// When true, skips Material/SizedBox wrapper (used inside PopoverController).
  final bool embedded;

  /// When set, operates on this specific page index instead of
  /// [currentPageIndexProvider]. Used by the sidebar "..." button.
  final int? pageIndex;

  @override
  ConsumerState<PageOptionsPanel> createState() => _PageOptionsPanelState();
}

class _PageOptionsPanelState extends ConsumerState<PageOptionsPanel> {
  /// Resolved page index: either the explicit [pageIndex] or current.
  int get _pageIndex =>
      widget.pageIndex ?? ref.read(currentPageIndexProvider);

  void _toggleBookmark() {
    final doc = ref.read(documentProvider);
    final idx = _pageIndex;
    final page = doc.pages[idx];
    final updated = page.copyWith(isBookmarked: !page.isBookmarked);
    final newPages = List<Page>.from(doc.pages)..[idx] = updated;
    final newDoc = doc.copyWith(pages: newPages);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
    widget.onClose();
  }

  void _showGoToPageDialog(BuildContext context) {
    final pageCount = ref.read(pageCountProvider);
    final pageManager = ref.read(pageManagerProvider.notifier);
    final navContext = Navigator.of(context, rootNavigator: true).context;
    widget.onClose();
    showGoToPageDialog(
      context: navContext,
      pageCount: pageCount,
      pageManager: pageManager,
    );
  }

  Future<void> _changeTemplate(BuildContext context) async {
    final docNotifier = ref.read(documentProvider.notifier);
    final pageManager = ref.read(pageManagerProvider.notifier);
    final page = ref.read(currentPageProvider);
    final navContext = Navigator.of(context, rootNavigator: true).context;
    widget.onClose();

    final result = await TemplatePicker.show(navContext);
    if (result == null) return;
    final t = result.template;
    final newBg = PageBackground(
      type: BackgroundType.template,
      color: result.backgroundColor?.toARGB32() ?? t.defaultBackgroundColor,
      templatePattern: t.pattern,
      templateSpacingMm: t.spacingMm,
      templateLineWidth: t.lineWidth,
      lineColor: result.lineColor?.toARGB32() ?? t.defaultLineColor,
    );
    docNotifier.updatePageBackground(page.id, newBg);
    pageManager.updateCurrentPage(page.copyWith(background: newBg));
  }

  void _copyPage(BuildContext context) {
    final doc = ref.read(documentProvider);
    final original = doc.pages[_pageIndex];
    ref.read(copiedPageProvider.notifier).state = original;
    widget.onClose();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sayfa kopyalandı')),
    );
  }

  void _pastePage(BuildContext context) {
    final copied = ref.read(copiedPageProvider);
    if (copied == null) return;
    _insertDeepCopy(copied);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sayfa yapıştırıldı')),
    );
  }

  void _duplicatePage() {
    final doc = ref.read(documentProvider);
    _insertDeepCopy(doc.pages[_pageIndex]);
  }

  /// Deep-copies [source] and inserts after current page index.
  void _insertDeepCopy(Page source) {
    final pageIndex = _pageIndex;
    final clone = Page(
      id: 'page_${DateTime.now().microsecondsSinceEpoch}',
      index: pageIndex + 1,
      size: source.size,
      background: source.background,
      layers: source.layers.map((l) => l.copyWith()).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final doc = ref.read(documentProvider);
    final newPages = List<Page>.from(doc.pages)..insert(pageIndex + 1, clone);
    final newDoc = doc.copyWith(pages: newPages, currentPageIndex: pageIndex + 1);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages, currentIndex: newDoc.currentPageIndex);
    widget.onClose();
  }

  void _exportPageAsPdf() {
    final doc = ref.read(documentProvider);
    final pageIndex = _pageIndex;
    final notifier = ref.read(exportProgressProvider.notifier);
    widget.onClose();
    performPagesPDFExport(
      notifier,
      pages: [doc.pages[pageIndex]],
      title: '${doc.title}_sayfa${pageIndex + 1}',
    );
  }

  Future<void> _deletePage(BuildContext context) async {
    final pageCount = ref.read(pageCountProvider);
    if (pageCount <= 1) {
      widget.onClose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Son sayfa silinemez')),
      );
      return;
    }

    final pageIndex = _pageIndex;
    final trashCallback = ref.read(pageTrashCallbackProvider);
    final docNotifier = ref.read(documentProvider.notifier);
    final pageManager = ref.read(pageManagerProvider.notifier);
    final doc = ref.read(documentProvider);

    // Close panel first — trash is reversible, no confirmation needed
    widget.onClose();

    // Soft-delete via callback if host app provided one
    if (trashCallback != null) {
      final page = doc.pages[pageIndex];
      await trashCallback(pageIndex, page);
    }

    // Remove page from document (both soft and hard paths need this)
    final freshDoc = docNotifier.currentDocument;
    final newDoc = freshDoc.removePage(pageIndex);
    docNotifier.updateDocument(newDoc);
    pageManager.initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
  }

  void _clearPage(BuildContext context) {
    final pageIndex = _pageIndex;
    final doc = ref.read(documentProvider);
    final historyManager = ref.read(historyManagerProvider.notifier);
    final navContext = Navigator.of(context, rootNavigator: true).context;
    widget.onClose();

    showDialog(
      context: navContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayfayı Temizle'),
        content: Text(
          'Sayfa ${pageIndex + 1} temizlensin mi?\nBu işlem geri alınabilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              historyManager.execute(ClearLayerCommand(layerIndex: doc.activeLayerIndex));
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final int pageIndex = widget.pageIndex ?? ref.watch(currentPageIndexProvider);
    final pageCount = ref.watch(pageCountProvider);
    final doc = ref.watch(documentProvider);
    final isBookmarked = doc.pages[pageIndex].isBookmarked;
    final hasCopiedPage = ref.watch(copiedPageProvider) != null;

    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageOptionsHeader(title: 'Sayfa ${pageIndex + 1}'),
          pageOptionsDivider(cs),
          PageOptionsMenuItem(
            icon: isBookmarked
                ? StarNoteIcons.bookmarkFilled
                : StarNoteIcons.bookmark,
            label: isBookmarked ? 'Yer imini kaldır' : 'Yer imi koy',
            onTap: _toggleBookmark,
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.copy,
            label: 'Sayfayı kopyala',
            onTap: () => _copyPage(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.paste,
            label: 'Sayfayı yapıştır',
            onTap: hasCopiedPage ? () => _pastePage(context) : null,
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.duplicate,
            label: 'Sayfayı çoğalt',
            onTap: _duplicatePage,
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.template,
            label: 'Şablonu değiştir',
            onTap: () => _changeTemplate(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.goToPage,
            label: 'Sayfaya git',
            trailing: pageOptionsChevronTrailing(cs, '${pageIndex + 1} / $pageCount'),
            onTap: () => _showGoToPageDialog(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.pdfFile,
            label: 'PDF olarak dışa aktar',
            onTap: _exportPageAsPdf,
          ),
          pageOptionsDivider(cs),
          PageOptionsMenuItem(
            icon: StarNoteIcons.pageClear,
            label: 'Sayfayı temizle',
            isDestructive: true,
            onTap: () => _clearPage(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.trash,
            label: 'Çöpe taşı',
            isDestructive: true,
            onTap: () => _deletePage(context),
          ),
          pageOptionsThickDivider(cs),
          PageOptionsSectionHeader(title: 'Ayarlar'),
          // TEMPORARILY DISABLED: Dual page mode
          // DualPageModeItem(onClose: widget.onClose),
          ScrollDirectionItem(onClose: widget.onClose),
          PageOptionsMenuItem(
            icon: StarNoteIcons.sliders,
            label: 'Araç Çubuğunu Düzenle',
            onTap: () {
              widget.onClose();
              showDialog<void>(
                context: context,
                builder: (_) => const Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ToolbarSettingsPanel(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
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
}
