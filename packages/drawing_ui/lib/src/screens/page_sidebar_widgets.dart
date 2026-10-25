/// Page thumbnail cell of the page sidebar grid
/// (docs/specs/52-editor-chrome.md, section 4 "Page sidebar").
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_core/drawing_core.dart' as core;

import 'package:drawing_ui/src/panels/panels.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';
import 'package:drawing_ui/src/widgets/widgets.dart';

/// Width / height of a grid cell: a portrait page inside the selection ring
/// inset plus the 48dp label row.
const double kPageGridItemAspectRatio = 0.55;

/// Width of the accent selection ring around a thumbnail.
const double _ringWidth = ChromeSpacing.xxs;

/// Selection ring (2dp accent) plus the 2dp surface gap around a thumbnail;
/// every grid cell keeps this inset so selection never shifts the layout.
const double kPageGridRingInset = _ringWidth * 2;

/// Single page thumbnail in the sidebar grid.
///
/// Selected: 2dp accent ring outside a 2dp gap and an accentContainer number
/// pill. The bookmark toggle (48dp) shows when set, and idle only on the
/// selected page. "..." opens [PageOptionsPanel].
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
    final newPages = List<core.Page>.from(doc.pages)..[widget.index] = updated;
    final newDoc = doc.copyWith(pages: newPages);
    ref.read(documentProvider.notifier).updateDocument(newDoc);
    ref.read(pageManagerProvider.notifier).initializeFromDocument(
          newDoc.pages,
          currentIndex: newDoc.currentPageIndex,
        );
  }

  void _open() {
    final onPageTap = widget.onPageTap;
    if (onPageTap != null) {
      onPageTap(widget.index);
    } else {
      ref.read(pageManagerProvider.notifier).goToPage(widget.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final sel = widget.isSelected;
    final bookmarked = widget.page.isBookmarked;
    final label = '${widget.index + 1}';
    const radius = BorderRadius.all(Radius.circular(ChromeRadius.sm));
    final hairline = Border.all(color: palette.border, width: 0.5);

    final thumbnail = DecoratedBox(
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: radius,
        boxShadow: DrawingShadows.page(Theme.of(context).brightness),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, c) => PageThumbnail(
            page: widget.page,
            cache: widget.thumbnailCache,
            width: c.maxWidth,
            height: c.maxHeight,
            backgroundColor: palette.paper,
            showPageNumber: false,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            selected: sel,
            label: 'Sayfa $label',
            child: GestureDetector(
              onTap: _open,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(kPageGridRingInset),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ChromeRadius.lg),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: sel ? 1 : 0),
                    width: _ringWidth,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumbnail,
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: hairline,
                        ),
                      ),
                    ),
                    if (bookmarked || sel)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _BookmarkToggle(
                          bookmarked: bookmarked,
                          onTap: _toggleBookmark,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: ChromeSizes.minTouchTarget,
          child: Row(
            children: [
              const SizedBox(width: ChromeSpacing.xs),
              _NumberPill(label: label, selected: sel),
              const Spacer(),
              ChromeIconButton(
                icon: ElyanotesIcons.more,
                tooltip: 'Sayfa seçenekleri',
                iconSize: ChromeIconSizes.md,
                visualKey: _moreKey,
                onPressed: _toggleMore,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 48dp bookmark toggle in a thumbnail corner: Fill accent when set.
class _BookmarkToggle extends StatelessWidget {
  const _BookmarkToggle({required this.bookmarked, required this.onTap});

  final bool bookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    return Semantics(
      button: true,
      toggled: bookmarked,
      label: bookmarked ? 'Yer imini kaldır' : 'Yer imi ekle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: ChromeSizes.minTouchTarget,
          child: Center(
            child: PhosphorIcon(
              bookmarked
                  ? ElyanotesIcons.bookmarkFilled
                  : ElyanotesIcons.bookmark,
              size: ChromeIconSizes.sm,
              color: bookmarked ? palette.accent : palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Page number; on the selected page an accentContainer pill.
class _NumberPill extends StatelessWidget {
  const _NumberPill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final style = textTheme.labelMedium?.copyWith(
      color: selected ? palette.accent : palette.textMuted,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChromeSpacing.sm,
        vertical: ChromeSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.accentContainer.withValues(alpha: selected ? 1 : 0),
        borderRadius: BorderRadius.circular(ChromeRadius.full),
      ),
      child: Text(label, style: style),
    );
  }
}
