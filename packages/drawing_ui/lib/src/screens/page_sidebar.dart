/// Page navigator sidebar: filter header and 2-column thumbnail grid
/// (docs/specs/52-editor-chrome.md, section 3 and 4 "Page sidebar").
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';

import 'audio_recordings_list.dart';
import 'page_sidebar_cells.dart';
import 'page_sidebar_filter_bar.dart';
import 'page_sidebar_widgets.dart';

/// Width of the docked tablet sidebar card.
const double kPageSidebarCardWidth = 256;

/// Layout footprint of the docked tablet sidebar: the card plus its left
/// margin. The canvas transform subtracts this so the page reflows.
const double kPageSidebarWidth = kPageSidebarCardWidth + ChromeSpacing.sm;

/// How the sidebar is presented.
enum PageSidebarVariant {
  /// Tablet: inset floating card that takes layout space next to the page.
  docked,

  /// Phone: full-height drawer over the page; width comes from the host.
  drawer,
}

/// Page navigator sidebar with a 2-column grid layout.
///
/// Automatically scrolls to the currently selected page when mounted
/// and when the page changes via external navigation.
class PageSidebar extends ConsumerStatefulWidget {
  const PageSidebar({
    super.key,
    required this.thumbnailCache,
    this.onPageTap,
    this.variant = PageSidebarVariant.docked,
  });

  final ThumbnailCache thumbnailCache;
  final ValueChanged<int>? onPageTap;
  final PageSidebarVariant variant;

  @override
  ConsumerState<PageSidebar> createState() => _PageSidebarState();
}

class _PageSidebarState extends ConsumerState<PageSidebar> {
  static const int _crossAxisCount = 2;
  static const double _gridPadding = ChromeSpacing.md;
  static const double _crossAxisSpacing = ChromeSpacing.md;
  static const double _mainAxisSpacing = ChromeSpacing.lg;

  late final ScrollController _scrollController;

  /// Grid width from the last layout; the docked card width until then.
  double _gridWidth = kPageSidebarCardWidth;

  double _offsetForIndex(int index) {
    final availableWidth = _gridWidth - _gridPadding * 2;
    final itemWidth =
        (availableWidth - _crossAxisSpacing * (_crossAxisCount - 1)) /
            _crossAxisCount;
    final itemHeight = itemWidth / kPageGridItemAspectRatio;
    final rowHeight = itemHeight + _mainAxisSpacing;
    final row = index ~/ _crossAxisCount;
    return (_gridPadding + row * rowHeight).clamp(0.0, double.infinity);
  }

  void _scrollToPage(int index, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    // During AnimatedSwitcher transitions two GridViews share this controller.
    if (_scrollController.positions.length != 1) return;
    final target = _offsetForIndex(index)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: ChromeDurations.fast,
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  void initState() {
    super.initState();
    final currentIndex = ref.read(currentPageIndexProvider);
    _scrollController =
        ScrollController(initialScrollOffset: _offsetForIndex(currentIndex));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _correctScrollIfNeeded());
  }

  void _correctScrollIfNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    // During AnimatedSwitcher transitions two GridViews share this controller.
    if (_scrollController.positions.length != 1) return;
    final idx = ref.read(currentPageIndexProvider);
    final target = _offsetForIndex(idx);
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0 && target > 0) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _correctScrollIfNeeded());
      return;
    }
    final clamped = target.clamp(0.0, max);
    if ((_scrollController.offset - clamped).abs() > 1) {
      _scrollController.jumpTo(clamped);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final audioEnabled = ref.watch(audioRecordingEnabledProvider);
    final rawFilter = ref.watch(sidebarFilterProvider);
    // Recordings filter is unavailable when audio is disabled.
    final filter = !audioEnabled && rawFilter == SidebarFilter.recordings
        ? SidebarFilter.allPages
        : rawFilter;

    ref.listen<int>(currentPageIndexProvider, (prev, next) {
      if (prev != next) _scrollToPage(next);
    });

    final content = Column(
      children: [
        PageSidebarFilterBar(
          filter: filter,
          showRecordings: audioEnabled,
          onFilterChanged: (f) =>
              ref.read(sidebarFilterProvider.notifier).state = f,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: ChromeDurations.normal,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(filter),
              child: filter == SidebarFilter.recordings
                  ? const AudioRecordingsList()
                  : _buildPageGrid(filter),
            ),
          ),
        ),
      ],
    );

    return widget.variant == PageSidebarVariant.docked
        ? _DockedCard(palette: palette, child: content)
        : _Drawer(palette: palette, child: content);
  }

  Widget _buildPageGrid(SidebarFilter filter) {
    final pageManager = ref.watch(pageManagerProvider);
    final allPages = pageManager.pages;
    final isBookmarkFilter = filter == SidebarFilter.bookmarked;
    final entries = <int>[
      for (int i = 0; i < allPages.length; i++)
        if (!isBookmarkFilter || allPages[i].isBookmarked) i,
    ];

    if (isBookmarkFilter && entries.isEmpty) {
      return const EmptyBookmarksState();
    }

    final showAddCell = !isBookmarkFilter;
    final itemCount = entries.length + (showAddCell ? 1 : 0);

    return LayoutBuilder(builder: (context, constraints) {
      _gridWidth = constraints.maxWidth;
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(_gridPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          crossAxisSpacing: _crossAxisSpacing,
          mainAxisSpacing: _mainAxisSpacing,
          childAspectRatio: kPageGridItemAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < entries.length) {
            final pageIndex = entries[index];
            return PageGridItem(
              page: allPages[pageIndex],
              index: pageIndex,
              isSelected: pageIndex == pageManager.currentIndex,
              thumbnailCache: widget.thumbnailCache,
              onPageTap: widget.onPageTap,
            );
          }
          return const AddPageCell();
        },
      );
    });
  }
}

/// Tablet card: `surface` fill, hairline, radius xl, chrome shadow, inset by
/// sm from the left and bottom edges of its [kPageSidebarWidth] footprint.
class _DockedCard extends StatelessWidget {
  const _DockedCard({required this.palette, required this.child});

  final ChromePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(ChromeRadius.xl));
    return SizedBox(
      width: kPageSidebarWidth,
      child: Padding(
        padding: const EdgeInsets.only(
          left: ChromeSpacing.sm,
          bottom: ChromeSpacing.sm,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: radius,
            border: Border.all(color: palette.border, width: 0.5),
            boxShadow: DrawingShadows.chrome(Theme.of(context).brightness),
          ),
          child: ClipRRect(borderRadius: radius, child: child),
        ),
      ),
    );
  }
}

/// Phone drawer: `surface` fill with xl right corners and the panel shadow.
class _Drawer extends StatelessWidget {
  const _Drawer({required this.palette, required this.child});

  final ChromePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.horizontal(
      right: Radius.circular(ChromeRadius.xl),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: radius,
        boxShadow: DrawingShadows.panel(Theme.of(context).brightness),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SafeArea(right: false, child: child),
      ),
    );
  }
}
