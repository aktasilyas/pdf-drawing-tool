/// Page navigator sidebar with filter bar and 2-column grid layout.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

import 'audio_recordings_list.dart';
import 'page_sidebar_widgets.dart';

/// Sidebar width for the page navigator panel.
const double kPageSidebarWidth = 240;

/// Page navigator sidebar with a 2-column grid layout.
///
/// Automatically scrolls to the currently selected page when mounted
/// and when the page changes via external navigation.
class PageSidebar extends ConsumerStatefulWidget {
  const PageSidebar({super.key, required this.thumbnailCache, this.onPageTap});
  final ThumbnailCache thumbnailCache;
  final ValueChanged<int>? onPageTap;

  @override
  ConsumerState<PageSidebar> createState() => _PageSidebarState();
}

class _PageSidebarState extends ConsumerState<PageSidebar> {
  static const int _crossAxisCount = 2;
  static const double _crossAxisSpacing = 12;
  static const double _mainAxisSpacing = 16;
  static const double _childAspectRatio = 0.58;
  static const double _gridPadding = 12;

  late final ScrollController _scrollController;

  double _offsetForIndex(int index) {
    final availableWidth = kPageSidebarWidth - _gridPadding * 2;
    final itemWidth =
        (availableWidth - _crossAxisSpacing * (_crossAxisCount - 1)) /
            _crossAxisCount;
    final itemHeight = itemWidth / _childAspectRatio;
    final rowHeight = itemHeight + _mainAxisSpacing;
    final row = index ~/ _crossAxisCount;
    return (_gridPadding + row * rowHeight).clamp(0.0, double.infinity);
  }

  void _scrollToPage(int index, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    // During AnimatedSwitcher transitions two GridViews share this controller.
    if (_scrollController.positions.length != 1) return;
    final target =
        _offsetForIndex(index).clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(target,
          duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
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
    final pageManager = ref.watch(pageManagerProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(sidebarFilterProvider);

    ref.listen<int>(currentPageIndexProvider, (prev, next) {
      if (prev != next) _scrollToPage(next);
    });

    return Container(
      width: kPageSidebarWidth,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
        border: Border(
            right: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Column(
        children: [
          _FilterBar(
            filter: filter,
            onFilterChanged: (f) =>
                ref.read(sidebarFilterProvider.notifier).state = f,
            cs: cs,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(filter),
                child: filter == SidebarFilter.recordings
                    ? const AudioRecordingsList()
                    : _buildPageGrid(pageManager, filter, cs, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageGrid(
    dynamic pageManager,
    SidebarFilter filter,
    ColorScheme cs,
    bool isDark,
  ) {
    final allPages = pageManager.pages;
    final isBookmarkFilter = filter == SidebarFilter.bookmarked;
    final filteredEntries = <_PageEntry>[];
    for (int i = 0; i < allPages.length; i++) {
      if (!isBookmarkFilter || allPages[i].isBookmarked) {
        filteredEntries.add(_PageEntry(page: allPages[i], originalIndex: i));
      }
    }

    final showAddCell = !isBookmarkFilter;
    final itemCount = filteredEntries.length + (showAddCell ? 1 : 0);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(_gridPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: _crossAxisSpacing,
        mainAxisSpacing: _mainAxisSpacing,
        childAspectRatio: _childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < filteredEntries.length) {
          final entry = filteredEntries[index];
          return PageGridItem(
            page: entry.page,
            index: entry.originalIndex,
            isSelected:
                entry.originalIndex == pageManager.currentIndex,
            thumbnailCache: widget.thumbnailCache,
            onPageTap: widget.onPageTap,
          );
        }
        return AddPageCell(cs: cs, isDark: isDark);
      },
    );
  }
}

/// Internal model pairing a page with its original index in the document.
class _PageEntry {
  const _PageEntry({required this.page, required this.originalIndex});
  final dynamic page;
  final int originalIndex;
}

/// Centered segmented tab bar: all pages / bookmarked / recordings.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onFilterChanged,
    required this.cs,
  });

  final SidebarFilter filter;
  final ValueChanged<SidebarFilter> onFilterChanged;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupBg = isDark
        ? cs.surfaceContainerHighest
        : cs.surfaceContainerHigh.withValues(alpha: 0.5);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Center(
        child: Container(
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: groupBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterTab(
                icon: StarNoteIcons.gridOn,
                isActive: filter == SidebarFilter.allPages,
                cs: cs,
                tooltip: 'Tum sayfalar',
                onTap: () => onFilterChanged(SidebarFilter.allPages),
              ),
              _FilterTab(
                icon: filter == SidebarFilter.bookmarked
                    ? StarNoteIcons.bookmarkFilled
                    : StarNoteIcons.bookmark,
                isActive: filter == SidebarFilter.bookmarked,
                cs: cs,
                tooltip: 'Yer imleri',
                onTap: () => onFilterChanged(SidebarFilter.bookmarked),
              ),
              _FilterTab(
                icon: StarNoteIcons.waveform,
                isActive: filter == SidebarFilter.recordings,
                cs: cs,
                tooltip: 'Ses kayitlari',
                onTap: () => onFilterChanged(SidebarFilter.recordings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single tab inside the segmented filter group.
class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.icon,
    required this.isActive,
    required this.cs,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final ColorScheme cs;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )]
                : null,
          ),
          child: Center(
            child: PhosphorIcon(
              icon,
              size: 18,
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
