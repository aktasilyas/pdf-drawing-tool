import 'dart:typed_data';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart'
    show renderThumbnail, pdfThumbnailCacheProvider;

/// A widget that displays a thumbnail preview of a page.
///
/// Handles thumbnail generation, caching, and display with loading/error states.
/// Supports selection styling and tap callbacks.
class PageThumbnail extends ConsumerStatefulWidget {
  /// The page to display a thumbnail for.
  final Page page;

  /// The thumbnail cache to use.
  final ThumbnailCache cache;

  /// Width of the thumbnail. Defaults to 150.
  final double width;

  /// Height of the thumbnail. Defaults to 200.
  final double height;

  /// Whether this thumbnail is currently selected.
  final bool isSelected;

  /// Whether to show the page number label.
  final bool showPageNumber;

  /// Callback when the thumbnail is tapped.
  final VoidCallback? onTap;

  /// Callback when the thumbnail is long-pressed.
  final VoidCallback? onLongPress;

  /// Background color for the thumbnail.
  final Color backgroundColor;

  const PageThumbnail({
    super.key,
    required this.page,
    required this.cache,
    this.width = 150,
    this.height = 200,
    this.isSelected = false,
    this.showPageNumber = true,
    this.onTap,
    this.onLongPress,
    this.backgroundColor = Colors.white,
  });

  @override
  ConsumerState<PageThumbnail> createState() => _PageThumbnailState();
}

class _PageThumbnailState extends ConsumerState<PageThumbnail> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(PageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate if page changed
    if (oldWidget.page.id != widget.page.id ||
        oldWidget.page.updatedAt != widget.page.updatedAt) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final cacheKey = ThumbnailGenerator.getCacheKey(widget.page);

      // Check cache first
      final cachedData = widget.cache.get(cacheKey);
      if (cachedData != null) {
        if (mounted) {
          setState(() {
            _thumbnailData = cachedData;
            _isLoading = false;
          });
        }
        return;
      }

      // Generate new thumbnail
      final data = await ThumbnailGenerator.generate(
        widget.page,
        width: widget.width,
        height: widget.height,
        backgroundColor: widget.backgroundColor,
      );

      if (data != null) {
        widget.cache.put(cacheKey, data);
        if (mounted) {
          setState(() {
            _thumbnailData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: widget.width,
        height: widget.height,
        constraints: BoxConstraints(
          maxWidth: widget.width,
          maxHeight: widget.height,
        ),
        decoration: BoxDecoration(
          border: widget.isSelected
              ? Border.all(color: colorScheme.primary, width: 3)
              : Border.all(
                  color: isDark 
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
          borderRadius: BorderRadius.circular(8),
          color: widget.backgroundColor,
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail content
              _buildThumbnailContent(),

              // Page number label
              if (widget.showPageNumber)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.page.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailContent() {
    final colorScheme = Theme.of(context).colorScheme;
    
    // SPECIAL CASE: PDF pages - use pdfPageRenderProvider directly
    if (widget.page.background.type == BackgroundType.pdf &&
        widget.page.background.pdfFilePath != null &&
        widget.page.background.pdfPageIndex != null) {
      return _buildPdfThumbnail();
    }

    // Normal page thumbnail rendering
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError || _thumbnailData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              StarNoteIcons.warningCircle,
              size: 32,
              color: colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to\ngenerate',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Image.memory(
      _thumbnailData!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        final colorScheme = Theme.of(context).colorScheme;
        return Center(
          child: PhosphorIcon(
            StarNoteIcons.brokenImage,
            size: 32,
            color: colorScheme.error.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }

  /// Build PDF thumbnail using renderThumbnail (low-res)
  Widget _buildPdfThumbnail() {
    final cacheKey = '${widget.page.background.pdfFilePath}|${widget.page.background.pdfPageIndex}';
    
    return Consumer(
      builder: (context, ref, child) {
        // 1. Önce thumbnail cache'e bak
        final thumbCache = ref.watch(pdfThumbnailCacheProvider);
        if (thumbCache.containsKey(cacheKey)) {
          return Image.memory(
            thumbCache[cacheKey]!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          );
        }
        
        // 2. Scroll sırasında loading yapma
        final shouldDefer = Scrollable.recommendDeferredLoadingForContext(context);
        if (!shouldDefer) {
          // ProviderContainer kullan (dispose-safe)
          final container = ProviderScope.containerOf(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            renderThumbnail(container, cacheKey);
          });
        }
        
        // 3. Basit placeholder
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: PhosphorIcon(
              StarNoteIcons.pdfFile,
              size: 24,
              color: Colors.grey[400],
            ),
          ),
        );
      },
    );
  }
}
