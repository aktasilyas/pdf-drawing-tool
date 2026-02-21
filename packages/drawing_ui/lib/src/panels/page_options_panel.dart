import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_picker.dart';

import 'page_options_widgets.dart';

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

    final controller = TextEditingController();
    void goTo(String value, BuildContext ctx) {
      final page = int.tryParse(value);
      if (page != null && page >= 1 && page <= pageCount) {
        Navigator.pop(ctx);
        pageManager.goToPage(page - 1);
      }
    }

    showDialog(
      context: navContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayfaya Git'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: '1 - $pageCount'),
          onSubmitted: (v) => goTo(v, ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(onPressed: () => goTo(controller.text, ctx), child: const Text('Git')),
        ],
      ),
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

  void _duplicatePage() {
    final doc = ref.read(documentProvider);
    final pageIndex = _pageIndex;
    final original = doc.pages[pageIndex];
    final duplicate = Page(
      id: 'page_${DateTime.now().microsecondsSinceEpoch}',
      index: pageIndex + 1,
      size: original.size,
      background: original.background,
      layers: original.layers.map((l) => l.copyWith()).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final newPages = List<Page>.from(doc.pages)..insert(pageIndex + 1, duplicate);
    final newDoc = doc.copyWith(pages: newPages, currentPageIndex: pageIndex + 1);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
    widget.onClose();
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

    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageOptionsHeader(title: 'Sayfa ${pageIndex + 1}'),
          _divider(cs),
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
            onTap: widget.onClose,
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
            trailing: _chevronTrailing(cs, '${pageIndex + 1} / $pageCount'),
            onTap: () => _showGoToPageDialog(context),
          ),
          _divider(cs),
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
          _thickDivider(cs),
          PageOptionsSectionHeader(title: 'Ayarlar'),
          // TEMPORARILY DISABLED: Dual page mode
          // DualPageModeItem(onClose: widget.onClose),
          ScrollDirectionItem(onClose: widget.onClose),
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

  Widget _chevronTrailing(ColorScheme cs, [String? label]) => Row(mainAxisSize: MainAxisSize.min, children: [
    if (label != null) ...[Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)), const SizedBox(width: 4)],
    PhosphorIcon(StarNoteIcons.chevronRight, size: 18, color: cs.onSurfaceVariant),
  ]);

  Widget _divider(ColorScheme cs) => Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant);
  Widget _thickDivider(ColorScheme cs) => Divider(height: 8, thickness: 8, color: cs.outlineVariant.withValues(alpha: 0.3));
}
