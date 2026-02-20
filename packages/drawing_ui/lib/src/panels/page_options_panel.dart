import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
// import 'package:drawing_ui/src/services/page_rotation_service.dart'; // TODO: Activate
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/template_picker/template_picker.dart';

import 'page_options_widgets.dart';

/// GoodNotes-style page options popup panel.
class PageOptionsPanel extends ConsumerStatefulWidget {
  const PageOptionsPanel({
    super.key,
    required this.onClose,
    this.embedded = false,
  });

  final VoidCallback onClose;

  /// When true, skips Material/SizedBox wrapper (used inside PopoverController).
  final bool embedded;

  @override
  ConsumerState<PageOptionsPanel> createState() => _PageOptionsPanelState();
}

class _PageOptionsPanelState extends ConsumerState<PageOptionsPanel> {
  void _showGoToPageDialog(BuildContext context) {
    final pageCount = ref.read(pageCountProvider);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayfaya Git'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: '1 - $pageCount'),
          onSubmitted: (v) => _goToPage(v, pageCount, ctx),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onClose();
            },
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => _goToPage(controller.text, pageCount, ctx),
            child: const Text('Git'),
          ),
        ],
      ),
    );
  }

  void _goToPage(String value, int pageCount, BuildContext ctx) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= pageCount) {
      Navigator.pop(ctx);
      widget.onClose();
      ref.read(pageManagerProvider.notifier).goToPage(page - 1);
    }
  }

  Future<void> _changeTemplate(BuildContext context) async {
    final result = await TemplatePicker.show(context);
    widget.onClose();
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
    final page = ref.read(currentPageProvider);
    ref.read(documentProvider.notifier).updatePageBackground(page.id, newBg);
    ref
        .read(pageManagerProvider.notifier)
        .updateCurrentPage(page.copyWith(background: newBg));
  }

  void _duplicatePage() {
    final doc = ref.read(documentProvider);
    final pageIndex = ref.read(currentPageIndexProvider);
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

    final pageIndex = ref.read(currentPageIndexProvider);
    final trashCallback = ref.read(pageTrashCallbackProvider);

    // Close panel first — trash is reversible, no confirmation needed
    widget.onClose();

    // Soft-delete via callback if host app provided one
    if (trashCallback != null) {
      final doc = ref.read(documentProvider);
      final page = doc.pages[pageIndex];
      await trashCallback(pageIndex, page);
    }

    // Remove page from document (both soft and hard paths need this)
    final doc = ref.read(documentProvider);
    final newDoc = doc.removePage(pageIndex);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
  }

  void _clearPage(BuildContext context) {
    final pageIndex = ref.read(currentPageIndexProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayfayı Temizle'),
        content: Text(
          'Sayfa ${pageIndex + 1} temizlensin mi?\nBu işlem geri alınabilir.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onClose();
            },
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onClose();
              final doc = ref.read(documentProvider);
              ref.read(historyManagerProvider.notifier).execute(
                    ClearLayerCommand(layerIndex: doc.activeLayerIndex),
                  );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  // TODO: Activate when ready
  // Future<void> _rotatePage(BuildContext context) async {
  //   final angle = await showRotatePageDialog(context);
  //   if (angle == null) return;
  //   final doc = ref.read(documentProvider);
  //   final pageIndex = ref.read(currentPageIndexProvider);
  //   final page = doc.pages[pageIndex];
  //   final rotated = PageRotationService.rotatePage(page, angle);
  //   final newPages = List<Page>.from(doc.pages)..[pageIndex] = rotated;
  //   final newDoc = doc.copyWith(pages: newPages);
  //   ref.read(documentProvider.notifier).updateDocument(newDoc);
  //   ref.read(pageManagerProvider.notifier).updateCurrentPage(rotated);
  //   widget.onClose();
  // }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pageIndex = ref.watch(currentPageIndexProvider);
    final pageCount = ref.watch(pageCountProvider);

    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageOptionsHeader(title: 'Sayfa ${pageIndex + 1}'),
          _divider(cs),
          PageOptionsMenuItem(
            icon: StarNoteIcons.bookmark,
            label: 'Sayfaya yer imi koy',
            onTap: widget.onClose,
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
          // TODO: Activate rotate page when ready
          // PageOptionsMenuItem(
          //   icon: StarNoteIcons.rotate,
          //   label: 'Sayfayı döndür',
          //   onTap: () => _rotatePage(context),
          // ),
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
          // _DualPageModeItem(onClose: widget.onClose),
          _ScrollDirectionItem(onClose: widget.onClose),
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

  Widget _chevronTrailing(ColorScheme cs, [String? label]) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
          ],
          PhosphorIcon(StarNoteIcons.chevronRight, size: 18, color: cs.onSurfaceVariant),
        ],
      );

  Widget _divider(ColorScheme cs) =>
      Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant);

  Widget _thickDivider(ColorScheme cs) => Divider(
        height: 8, thickness: 8,
        color: cs.outlineVariant.withValues(alpha: 0.3),
      );
}

/// Dual page (side-by-side) mode toggle.
// ignore: unused_element
class _DualPageModeItem extends ConsumerWidget {
  const _DualPageModeItem({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDual = ref.watch(dualPageModeProvider);
    return PageOptionsToggleItem(
      icon: StarNoteIcons.splitView,
      label: 'Çift sayfa görünümü',
      value: isDual,
      onChanged: (v) => ref.read(dualPageModeProvider.notifier).state = v,
    );
  }
}

/// Scroll direction toggle extracted to keep PageOptionsPanel under 300 lines.
class _ScrollDirectionItem extends ConsumerWidget {
  const _ScrollDirectionItem({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direction = ref.watch(scrollDirectionProvider);
    final isHorizontal = direction == Axis.horizontal;
    final cs = Theme.of(context).colorScheme;
    return PageOptionsMenuItem(
      icon: isHorizontal
          ? StarNoteIcons.scrollDirection
          : StarNoteIcons.scrollDirectionVertical,
      label: 'Kaydırma yönü',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isHorizontal ? 'Yatay' : 'Dikey',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          PhosphorIcon(
            StarNoteIcons.chevronRight,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () {
        ref.read(scrollDirectionProvider.notifier).state =
            isHorizontal ? Axis.vertical : Axis.horizontal;
      },
    );
  }
}
