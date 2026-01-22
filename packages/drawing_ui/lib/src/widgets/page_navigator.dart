import 'package:flutter/material.dart' hide Page;
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/widgets/page_thumbnail.dart';

/// A navigation bar widget that displays page thumbnails and allows page management.
///
/// Shows a horizontal scrollable list of page thumbnails with options to
/// add, delete, duplicate, and navigate between pages.
class PageNavigator extends StatefulWidget {
  /// The page manager containing all pages.
  final PageManager pageManager;

  /// The thumbnail cache to use for page previews.
  final ThumbnailCache cache;

  /// Callback when a different page is selected.
  final ValueChanged<int> onPageChanged;

  /// Callback to add a new page. If null, add button is hidden.
  final VoidCallback? onAddPage;

  /// Callback to delete a page. If null, delete option is hidden.
  final ValueChanged<int>? onDeletePage;

  /// Callback to duplicate a page. If null, duplicate option is hidden.
  final ValueChanged<int>? onDuplicatePage;

  /// Height of the navigator bar. Defaults to 120.
  final double height;

  /// Width of each thumbnail. Defaults to 80.
  final double thumbnailWidth;

  /// Height of each thumbnail. Defaults to 100.
  final double thumbnailHeight;

  /// Whether to show the page count indicator.
  final bool showPageCount;

  /// Background color of the navigator bar.
  final Color? backgroundColor;

  const PageNavigator({
    super.key,
    required this.pageManager,
    required this.cache,
    required this.onPageChanged,
    this.onAddPage,
    this.onDeletePage,
    this.onDuplicatePage,
    this.height = 120,
    this.thumbnailWidth = 80,
    this.thumbnailHeight = 100,
    this.showPageCount = true,
    this.backgroundColor,
  });

  @override
  State<PageNavigator> createState() => _PageNavigatorState();
}

class _PageNavigatorState extends State<PageNavigator> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PageNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to current page when it changes
    if (oldWidget.pageManager.currentIndex !=
        widget.pageManager.currentIndex) {
      _scrollToCurrentPage();
    }
  }

  void _scrollToCurrentPage() {
    if (!_scrollController.hasClients) return;

    final index = widget.pageManager.currentIndex;
    final itemWidth = widget.thumbnailWidth + 16; // thumbnail + padding
    final targetOffset = index * itemWidth;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageTap(int index) {
    widget.onPageChanged(index);
  }

  void _handlePageLongPress(int index) {
    if (widget.onDeletePage == null && widget.onDuplicatePage == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onDuplicatePage != null)
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('Duplicate Page'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDuplicatePage!(index);
                },
              ),
            if (widget.onDeletePage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Page'),
                textColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    if (widget.pageManager.pageCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last page')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text('Delete page ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeletePage!(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor =
        widget.backgroundColor ?? theme.scaffoldBackgroundColor;

    return Container(
      height: widget.height,
      constraints: BoxConstraints(maxHeight: widget.height),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Page count indicator
          if (widget.showPageCount && widget.pageManager.pageCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Page ${widget.pageManager.currentIndex + 1} of ${widget.pageManager.pageCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          // Thumbnail list
          Expanded(
            child: widget.pageManager.pages.isEmpty
                ? Center(
                    child: Text(
                      'No pages',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: widget.pageManager.pageCount +
                        (widget.onAddPage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Add page button
                      if (index == widget.pageManager.pageCount) {
                        return _buildAddButton();
                      }

                      // Page thumbnail
                      final page = widget.pageManager.pages[index];
                      final isSelected =
                          index == widget.pageManager.currentIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _handlePageTap(index),
                          onLongPress: () => _handlePageLongPress(index),
                          child: PageThumbnail(
                            page: page,
                            cache: widget.cache,
                            width: widget.thumbnailWidth,
                            height: widget.thumbnailHeight,
                            isSelected: isSelected,
                            showPageNumber: true,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: widget.onAddPage,
        child: Container(
          width: widget.thumbnailWidth,
          height: widget.thumbnailHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 32,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                'Add Page',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
