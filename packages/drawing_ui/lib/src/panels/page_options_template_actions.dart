import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_picker.dart';

/// Template, paper and cover changes of the page options panel.
mixin PageOptionsTemplateActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Closes the popover that hosts the panel.
  VoidCallback get onPanelClose;

  /// Page the panel operates on.
  int get targetPageIndex;

  Future<void> changeTemplate(BuildContext context) async {
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

    onPanelClose();

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
      _applyCoverChange(newCover, result.paperSize.toPageSize(), docNotifier,
          pageManager, currentIdx);
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
        pageManager.updateCurrentPage(coverPage.copyWith(background: coverBg));
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
}

/// Resolve PageSize (px) → PaperSize (mm) by matching known presets.
PaperSize _resolvePaperSize(PageSize pageSize) {
  const presets = [
    PaperSize.a4,
    PaperSize.a5,
    PaperSize.a6,
    PaperSize.letter,
    PaperSize.legal,
    PaperSize.square,
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

bool _pageSizeMatches(PageSize a, PageSize b) =>
    (a.width - b.width).abs() < 2 && (a.height - b.height).abs() < 2;
