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
    this.documentTitle,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onAddPage,
    this.onExport,
    this.compact = false,
  });

  final VoidCallback onClose;

  /// When true, skips Material/SizedBox wrapper (used inside PopoverController).
  final bool embedded;

  /// When set, operates on this specific page index instead of
  /// [currentPageIndexProvider]. Used by the sidebar "..." button.
  final int? pageIndex;

  /// Document title shown at top of panel (used by MediumToolbar).
  final String? documentTitle;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;

  /// Callback to open the Add Page panel (used when the button is hidden).
  final VoidCallback? onAddPage;

  /// Callback to open the Export panel (used when the button is hidden).
  final VoidCallback? onExport;

  /// When true, uses smaller spacing/fonts (MediumToolbar popup).
  final bool compact;

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
    final currentIdx = ref.read(currentPageIndexProvider);
    final doc = ref.read(documentProvider);
    final navContext = Navigator.of(context, rootNavigator: true).context;

    // Resolve current template from page background
    final bg = page.background;
    final currentTemplate = bg.templatePattern != null
        ? TemplateRegistry.getByPattern(bg.templatePattern!).firstOrNull
        : null;
    final currentPaperColor = Color(bg.color);
    final currentPaperSize = _resolvePaperSize(page.size);

    // Resolve current cover from cover page
    final coverPage = doc.pages.where((p) => p.isCover).firstOrNull;
    final currentCover = coverPage?.background.coverId != null
        ? CoverRegistry.byId(coverPage!.background.coverId!)
        : null;

    widget.onClose();

    final result = await TemplatePicker.show(
      navContext,
      initialTemplate: currentTemplate,
      initialPaperSize: currentPaperSize,
      initialPaperColor: currentPaperColor,
      initialCover: currentCover,
    );
    if (result == null) return;

    // Apply cover change only if cover selection changed
    final newCover = result.cover;
    final coverChanged = newCover != currentCover;
    if (coverChanged && newCover != null) {
      _applyCoverChange(
          newCover, result.paperSize.toPageSize(),
          docNotifier, pageManager, currentIdx);
    }

    // Apply template/paper change only if something changed
    final t = result.template;
    final newBgColor =
        result.backgroundColor?.toARGB32() ?? t.defaultBackgroundColor;
    final newLineColor = result.lineColor?.toARGB32() ?? t.defaultLineColor;
    final templateChanged = t.pattern != bg.templatePattern ||
        newBgColor != bg.color ||
        newLineColor != bg.lineColor;

    // Apply paper size change (orientation / format)
    final newPageSize = result.paperSize.toPageSize();
    final sizeChanged = newPageSize != page.size;

    if (templateChanged || sizeChanged) {
      var updated = page;
      if (templateChanged) {
        final newBg = PageBackground(
          type: BackgroundType.template,
          color: newBgColor,
          templatePattern: t.pattern,
          templateSpacingMm: t.spacingMm,
          templateLineWidth: t.lineWidth,
          lineColor: newLineColor,
        );
        updated = updated.copyWith(background: newBg);
        docNotifier.updatePageBackground(page.id, newBg);
      }
      if (sizeChanged) {
        updated = updated.copyWith(size: newPageSize);
        final freshDoc = docNotifier.currentDocument;
        final pages = List<Page>.from(freshDoc.pages);
        final idx = pages.indexWhere((p) => p.id == page.id);
        if (idx >= 0) {
          pages[idx] = pages[idx].copyWith(size: newPageSize);
        }
        docNotifier.updateDocument(freshDoc.copyWith(pages: pages));
      }
      pageManager.updateCurrentPage(updated);
    }

    // Always sync cover page size with paper orientation
    _syncCoverSize(newPageSize, docNotifier);
  }

  /// Ensures the cover page matches the current paper size/orientation.
  void _syncCoverSize(PageSize targetSize, DocumentNotifier docNotifier) {
    final freshDoc = docNotifier.currentDocument;
    final coverIdx = freshDoc.pages.indexWhere((p) => p.isCover);
    if (coverIdx < 0) return;
    final coverPage = freshDoc.pages[coverIdx];
    if (coverPage.size == targetSize) return;
    final pages = List<Page>.from(freshDoc.pages)
      ..[coverIdx] = coverPage.copyWith(size: targetSize);
    docNotifier.updateDocument(freshDoc.copyWith(pages: pages));
  }

  void _applyCoverChange(
    Cover cover,
    PageSize coverSize,
    DocumentNotifier docNotifier,
    PageManagerNotifier pageManager,
    int currentIdx,
  ) {
    final coverBg = PageBackground(
      type: BackgroundType.cover,
      coverId: cover.id,
      color: cover.primaryColor,
    );
    final doc = docNotifier.currentDocument;
    final coverIdx = doc.pages.indexWhere((p) => p.isCover);

    if (coverIdx >= 0) {
      final coverPage = doc.pages[coverIdx];
      docNotifier.updatePageBackground(coverPage.id, coverBg);
      if (coverIdx == currentIdx) {
        pageManager.updateCurrentPage(
            coverPage.copyWith(background: coverBg));
      }
    } else {
      final coverPage = Page.createCover(
        index: 0,
        size: coverSize,
        background: coverBg,
      );
      final newPages = List<Page>.from(doc.pages)..insert(0, coverPage);
      final newDoc = doc.copyWith(
        pages: newPages,
        currentPageIndex: currentIdx + 1,
      );
      docNotifier.updateDocument(newDoc);
      pageManager.initializeFromDocument(
        newDoc.pages,
        currentIndex: newDoc.currentPageIndex,
      );
    }
  }

  /// Resolve PageSize (px) → PaperSize (mm) by matching known presets.
  static PaperSize _resolvePaperSize(PageSize pageSize) {
    const presets = [
      PaperSize.a4, PaperSize.a5, PaperSize.a6,
      PaperSize.letter, PaperSize.legal, PaperSize.square,
      PaperSize.widescreen,
    ];
    for (final ps in presets) {
      if (_pageSizeMatches(ps.toPageSize(), pageSize)) return ps;
      if (_pageSizeMatches(ps.landscape.toPageSize(), pageSize)) {
        return ps.landscape;
      }
    }
    return pageSize.isLandscape ? PaperSize.a4.landscape : PaperSize.a4;
  }

  static bool _pageSizeMatches(PageSize a, PageSize b) =>
      (a.width - b.width).abs() < 2 && (a.height - b.height).abs() < 2;

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

    final c = widget.compact;
    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.documentTitle != null) ...[
            PageOptionsHeader(title: widget.documentTitle!, compact: c),
            pageOptionsDivider(cs),
            PageOptionsMenuItem(
              icon: StarNoteIcons.editPencil,
              label: 'Yeniden Adlandır',
              compact: c,
              onTap: () {
                widget.onClose();
                widget.onRenameDocument?.call();
              },
            ),
            PageOptionsMenuItem(
              icon: StarNoteIcons.trash,
              label: 'Çöpe Taşı',
              isDestructive: true,
              compact: c,
              onTap: () {
                widget.onClose();
                widget.onDeleteDocument?.call();
              },
            ),
            if (widget.onExport != null)
              PageOptionsMenuItem(
                icon: StarNoteIcons.exportIcon,
                label: 'Dışa Aktar',
                compact: c,
                onTap: widget.onExport,
              ),
            pageOptionsThickDivider(cs, compact: c),
          ],
          PageOptionsHeader(title: 'Sayfa ${pageIndex + 1}', compact: c),
          pageOptionsDivider(cs),
          if (widget.onAddPage != null)
            PageOptionsMenuItem(
              icon: StarNoteIcons.pageAdd,
              label: 'Sayfa Ekle',
              compact: c,
              onTap: widget.onAddPage,
            ),
          PageOptionsMenuItem(
            icon: isBookmarked
                ? StarNoteIcons.bookmarkFilled
                : StarNoteIcons.bookmark,
            label: isBookmarked ? 'Yer imini kaldır' : 'Yer imi koy',
            compact: c,
            onTap: _toggleBookmark,
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.copy,
            label: 'Sayfayı kopyala',
            compact: c,
            onTap: () => _copyPage(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.paste,
            label: 'Sayfayı yapıştır',
            compact: c,
            onTap: hasCopiedPage ? () => _pastePage(context) : null,
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.duplicate,
            label: 'Sayfayı çoğalt',
            compact: c,
            onTap: _duplicatePage,
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.template,
            label: 'Şablonu değiştir',
            compact: c,
            onTap: () => _changeTemplate(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.goToPage,
            label: 'Sayfaya git',
            compact: c,
            trailing: pageOptionsChevronTrailing(cs, '${pageIndex + 1} / $pageCount'),
            onTap: () => _showGoToPageDialog(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.pdfFile,
            label: 'PDF olarak dışa aktar',
            compact: c,
            onTap: _exportPageAsPdf,
          ),
          pageOptionsDivider(cs),
          PageOptionsMenuItem(
            icon: StarNoteIcons.pageClear,
            label: 'Sayfayı temizle',
            isDestructive: true,
            compact: c,
            onTap: () => _clearPage(context),
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.trash,
            label: 'Çöpe taşı',
            isDestructive: true,
            compact: c,
            onTap: () => _deletePage(context),
          ),
          pageOptionsThickDivider(cs, compact: c),
          PageOptionsSectionHeader(title: 'Ayarlar', compact: c),
          // TEMPORARILY DISABLED: Dual page mode
          // DualPageModeItem(onClose: widget.onClose),
          ScrollDirectionItem(onClose: widget.onClose, compact: c),
          PageOptionsMenuItem(
            icon: StarNoteIcons.sliders,
            label: 'Araç Çubuğunu Düzenle',
            compact: c,
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
          SizedBox(height: c ? 4 : 8),
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
