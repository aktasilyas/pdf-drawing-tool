import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';

import 'export_panel.dart' show performPagesPDFExport;
import 'page_options_widgets.dart';
import 'page_structure_undo.dart';

/// Page level actions of the page options panel (bookmark, copy, delete...).
mixin PageOptionsActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Closes the popover that hosts the panel.
  VoidCallback get onPanelClose;

  /// Page the panel operates on.
  int get targetPageIndex;

  void toggleBookmark() {
    final doc = ref.read(documentProvider);
    final idx = targetPageIndex;
    final page = doc.pages[idx];
    final updated = page.copyWith(isBookmarked: !page.isBookmarked);
    final newPages = List<Page>.from(doc.pages)..[idx] = updated;
    final newDoc = doc.copyWith(pages: newPages);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
    onPanelClose();
  }

  void showGoToPage(BuildContext context) {
    final pageCount = ref.read(pageCountProvider);
    final pageManager = ref.read(pageManagerProvider.notifier);
    final navContext = Navigator.of(context, rootNavigator: true).context;
    onPanelClose();
    showGoToPageDialog(
      context: navContext,
      pageCount: pageCount,
      pageManager: pageManager,
    );
  }

  void copyPage(BuildContext context) {
    final doc = ref.read(documentProvider);
    final original = doc.pages[targetPageIndex];
    ref.read(copiedPageProvider.notifier).state = original;
    onPanelClose();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sayfa kopyalandı')),
    );
  }

  void pastePage(BuildContext context) {
    final copied = ref.read(copiedPageProvider);
    if (copied == null) return;
    _insertCopy(context, copied, 'Sayfa yapıştırıldı');
  }

  void duplicatePage(BuildContext context) {
    final doc = ref.read(documentProvider);
    _insertCopy(context, doc.pages[targetPageIndex], 'Sayfa çoğaltıldı');
  }

  /// Inserts a copy of [source] (fresh ids) after the target page and offers
  /// an undo SnackBar.
  void _insertCopy(BuildContext context, Page source, String message) {
    // The popover context goes away on close, so grab these first.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final actions = ref.read(pageStructureActionsProvider);
    final change = actions.insertCopy(targetPageIndex, source);
    onPanelClose();
    showPageUndoSnackBar(messenger, actions, change, message);
  }

  void exportPageAsPdf() {
    final doc = ref.read(documentProvider);
    final pageIndex = targetPageIndex;
    final notifier = ref.read(exportProgressProvider.notifier);
    final strings = context.drawingStrings.export;
    onPanelClose();
    final title = doc.title.isEmpty ? strings.fallbackFileName : doc.title;
    performPagesPDFExport(
      notifier,
      strings: strings,
      pages: [doc.pages[pageIndex]],
      title: strings.pageFileName(title, pageIndex + 1),
      pdfPaths: ref.read(pdfPathResolverProvider),
    );
  }

  /// Deletes the page and offers an undo SnackBar.
  Future<void> deletePage(BuildContext context) async {
    // The popover context goes away on close, so grab these first.
    final messenger = ScaffoldMessenger.of(context);
    final index = targetPageIndex;
    if (ref.read(pageCountProvider) <= 1) {
      onPanelClose();
      messenger.showSnackBar(
        const SnackBar(content: Text('Son sayfa silinemez')),
      );
      return;
    }
    final actions = ref.read(pageStructureActionsProvider);

    // Close panel first, the delete is undoable and needs no confirmation.
    onPanelClose();

    final deleted = await actions.deletePage(index);
    if (deleted == null) return;
    // A second delete makes the first one final.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Sayfa silindi'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () => actions.restorePage(deleted),
          ),
        ),
      );
  }

  void clearPage(BuildContext context) {
    final pageIndex = targetPageIndex;
    final doc = ref.read(documentProvider);
    final historyManager = ref.read(historyManagerProvider.notifier);
    final navContext = Navigator.of(context, rootNavigator: true).context;
    onPanelClose();

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
              historyManager.execute(
                ClearLayerCommand(layerIndex: doc.activeLayerIndex),
                pageId: doc.pages[pageIndex].id,
              );
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}
