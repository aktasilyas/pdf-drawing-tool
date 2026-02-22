/// Widgets for the page navigator sidebar: grid item and add-page cell.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart' as core;

import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

/// Single page thumbnail in the sidebar grid.
///
/// Shows bookmark overlay (top-right) and "..." button that opens
/// [PageOptionsPanel] via [PopoverController].
class PageGridItem extends ConsumerStatefulWidget {
  const PageGridItem({
    super.key,
    required this.page,
    required this.index,
    required this.isSelected,
    required this.thumbnailCache,
    this.onPageTap,
  });

  final core.Page page;
  final int index;
  final bool isSelected;
  final ThumbnailCache thumbnailCache;
  final ValueChanged<int>? onPageTap;

  @override
  ConsumerState<PageGridItem> createState() => _PageGridItemState();
}

class _PageGridItemState extends ConsumerState<PageGridItem> {
  final PopoverController _popover = PopoverController();
  final GlobalKey _moreKey = GlobalKey();

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  void _toggleMore() {
    if (_popover.isShowing) {
      _popover.hide();
      return;
    }
    _popover.show(
      context: context,
      anchorKey: _moreKey,
      maxWidth: 320,
      onDismiss: () {},
      child: PageOptionsPanel(
        onClose: () => _popover.hide(),
        embedded: true,
        pageIndex: widget.index,
      ),
    );
  }

  void _toggleBookmark() {
    final doc = ref.read(documentProvider);
    final page = doc.pages[widget.index];
    final updated = page.copyWith(isBookmarked: !page.isBookmarked);
    final newPages = List<core.Page>.from(doc.pages)
      ..[widget.index] = updated;
    final newDoc = doc.copyWith(pages: newPages);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sel = widget.isSelected;
    final page = widget.page;

    return GestureDetector(
      onTap: () => (widget.onPageTap ??
          (i) => ref.read(pageManagerProvider.notifier).goToPage(i))(
        widget.index,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Thumbnail
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainer : cs.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? cs.primary : cs.outlineVariant,
                        width: sel ? 2 : 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: sel ? 0.12 : 0.05),
                          blurRadius: sel ? 8 : 3,
                          offset: Offset(0, sel ? 2 : 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: PageThumbnail(
                        page: page,
                        cache: widget.thumbnailCache,
                        width: 102,
                        height: 140,
                        isSelected: sel,
                        showPageNumber: false,
                      ),
                    ),
                  ),
                ),
                // Bookmark icon
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _toggleBookmark,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Center(
                        child: PhosphorIcon(
                          page.isBookmarked
                              ? StarNoteIcons.bookmarkFilled
                              : StarNoteIcons.bookmark,
                          size: 16,
                          color: page.isBookmarked
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  color: sel ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GestureDetector(
                key: _moreKey,
                onTap: _toggleMore,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: PhosphorIcon(
                      StarNoteIcons.more,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Sayfa ekle" cell in the sidebar grid. Uses [PopoverController] to show
/// the same arrow-popover as the toolbar's add-page button.
class AddPageCell extends StatefulWidget {
  const AddPageCell({super.key, required this.cs, required this.isDark});
  final ColorScheme cs;
  final bool isDark;

  @override
  State<AddPageCell> createState() => _AddPageCellState();
}

class _AddPageCellState extends State<AddPageCell> {
  final PopoverController _popover = PopoverController();
  final GlobalKey _anchorKey = GlobalKey();

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_popover.isShowing) {
      _popover.hide();
      return;
    }
    _popover.show(
      context: context,
      anchorKey: _anchorKey,
      maxWidth: 320,
      onDismiss: () {},
      child: AddPagePanel(onClose: () => _popover.hide(), embedded: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return GestureDetector(
      key: _anchorKey,
      onTap: _toggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDark ? cs.surfaceContainer : cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(StarNoteIcons.plus, size: 24, color: cs.primary),
                  const SizedBox(height: 4),
                  Text(
                    'Sayfa ekle',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
