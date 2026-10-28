import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_picker.dart';

/// Template, paper and cover changes of the page options panel.
mixin PageOptionsTemplateActions<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Closes the popover that hosts the panel.
  VoidCallback get onPanelClose;

  /// Page the panel operates on.
  int get targetPageIndex;

  /// Opens the template picker for the target page and applies the result
  /// to that page only. Confirming the picker unchanged is a no-op, so a PDF
  /// or cover background is replaced only by an explicit new choice, which
  /// can then be undone from the SnackBar.
  Future<void> changeTemplate(BuildContext context) async {
    final docNotifier = ref.read(documentProvider.notifier);
    final pageManager = ref.read(pageManagerProvider.notifier);
    final doc = ref.read(documentProvider);
    final targetIdx = targetPageIndex;
    if (targetIdx < 0 || targetIdx >= doc.pages.length) return;
    final page = doc.pages[targetIdx];
    final currentIdx = ref.read(currentPageIndexProvider);
    final navContext = Navigator.of(context, rootNavigator: true).context;
    // The popover context goes away on close, so grab these first.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final strings = context.drawingStrings;
    // Outlives the panel, so the SnackBar undo can still read providers.
    final container = ProviderScope.containerOf(context, listen: false);

    // Resolve the target page's template, color and paper size.
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

    final t = result.template;
    final newBgColor =
        result.backgroundColor?.toARGB32() ?? t.defaultBackgroundColor;
    final newLineColor = result.lineColor?.toARGB32() ?? t.defaultLineColor;
    final templateChanged = bg.templatePattern != null
        ? t.pattern != bg.templatePattern ||
            newBgColor != bg.color ||
            newLineColor != bg.lineColor ||
            !mapEquals(t.extraData, bg.templateExtraData)
        // No template to compare with (PDF, cover, legacy): only a choice
        // that differs from what the picker opened with counts.
        : t != (currentTemplate ?? TemplateRegistry.blank) ||
            newBgColor != bg.color;
    // Compare with the size the picker opened with, so a page whose size is
    // not a preset (e.g. an imported PDF page) is not resized to one.
    final sizeChanged = result.paperSize != currentPaperSize;
    if (!templateChanged && !sizeChanged) return;

    final newPageSize = result.paperSize.toPageSize();
    final newBg = PageBackground.fromTemplate(
      t,
      color: newBgColor,
      lineColor: newLineColor,
    );
    // The cover follows the paper size; remember it for undo.
    final previousCoverSize = docNotifier.currentDocument.pages
        .where((p) => p.isCover && p.id != page.id)
        .firstOrNull
        ?.size;
    _updatePage(
      container,
      page.id,
      background: templateChanged ? newBg : null,
      size: sizeChanged ? newPageSize : null,
      coverSize: sizeChanged ? newPageSize : null,
    );

    if (templateChanged && _isContentBackground(bg)) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.pages.backgroundReplaced),
            action: SnackBarAction(
              label: strings.toolbar.undo,
              onPressed: () => _updatePage(
                container,
                page.id,
                background: bg,
                size: sizeChanged ? page.size : null,
                coverSize: sizeChanged ? previousCoverSize : null,
              ),
            ),
          ),
        );
    }
  }

  /// Sets [background] and/or [size] of the page with [pageId] and, when
  /// [coverSize] is set, the size of the cover page. The page manager keeps
  /// its current page (the document's index is not kept in sync with
  /// navigation, so it must not be used here).
  void _updatePage(
    ProviderContainer container,
    String pageId, {
    PageBackground? background,
    PageSize? size,
    PageSize? coverSize,
  }) {
    final docNotifier = container.read(documentProvider.notifier);
    final freshDoc = docNotifier.currentDocument;
    final idx = freshDoc.pages.indexWhere((p) => p.id == pageId);
    if (idx < 0) return;
    var updated = freshDoc.pages[idx];
    if (background != null) updated = updated.copyWith(background: background);
    if (size != null) updated = updated.copyWith(size: size);
    final pages = List<Page>.from(freshDoc.pages)..[idx] = updated;
    docNotifier.updateDocument(freshDoc.copyWith(pages: pages));
    if (coverSize != null) _syncCoverSize(coverSize, docNotifier);
    container.read(pageManagerProvider.notifier).initializeFromDocument(
          docNotifier.currentDocument.pages,
          currentIndex: container.read(currentPageIndexProvider),
        );
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

/// PDF (also imported images) and cover backgrounds hold content that a
/// template cannot recreate.
bool _isContentBackground(PageBackground bg) =>
    bg.type == BackgroundType.pdf || bg.type == BackgroundType.cover;

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
