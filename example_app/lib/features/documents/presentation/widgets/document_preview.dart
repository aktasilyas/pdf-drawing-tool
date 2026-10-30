/// ElyaNotes Document Preview Widgets
///
/// Doküman önizleme widget'ları (PDF, Image preview).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_preview_provider.dart';

/// Document preview widget for PDF and Image documents.
///
/// Shows the first page background. It comes from
/// [documentPreviewBackgroundProvider], so a rebuild does no storage work;
/// a missing or corrupt document leaves the plain paper of the tile.
class DocumentPreview extends ConsumerWidget {
  final DocumentInfo document;

  const DocumentPreview({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final background = ref.watch(
      documentPreviewBackgroundProvider(
        (id: document.id, updatedAt: document.updatedAt),
      ),
    );
    return background.when(
      loading: () => const _LoadingIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (bg) => bg == null ? const SizedBox.shrink() : _preview(bg),
    );
  }

  Widget _preview(core.PageBackground bg) {
    // Embedded image data (image imports)
    if (bg.pdfData != null) return _ImagePreview(data: bg.pdfData!);

    // Lazy-loaded PDF (render thumbnail from file path)
    if (bg.pdfFilePath != null && bg.pdfPageIndex != null) {
      return _PdfThumbnail(cacheKey: '${bg.pdfFilePath}|${bg.pdfPageIndex}');
    }
    return const SizedBox.shrink();
  }
}

/// Renders PDF thumbnail from file path using existing render infrastructure
class _PdfThumbnail extends ConsumerStatefulWidget {
  final String cacheKey;
  const _PdfThumbnail({required this.cacheKey});

  @override
  ConsumerState<_PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends ConsumerState<_PdfThumbnail> {
  bool _renderFailed = false;

  /// Pixel width of the current preview (tile width x DPR); null before the
  /// first dependency pass.
  int? _width;

  /// Preview key being rendered; at most one render is in flight per tile.
  String? _inFlight;

  /// Preview key this tile pins in the cache (see [LibraryPreviewPins]).
  String? _pinned;
  late final LibraryPreviewPins _pins = ref.read(libraryPreviewPinsProvider);

  String get _key => libraryPreviewKey(widget.cacheKey, _width!);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-render when the DPR changes (window moved to another display).
    final width = libraryPreviewWidth(MediaQuery.devicePixelRatioOf(context));
    if (width != _width) {
      _width = width;
      _renderFailed = false;
    }
  }

  @override
  void didUpdateWidget(_PdfThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) _renderFailed = false;
  }

  @override
  void dispose() {
    final pinned = _pinned;
    if (pinned != null) _pins.unpin(pinned);
    super.dispose();
  }

  void _pin(String key) {
    if (_pinned == key) return;
    final old = _pinned;
    if (old != null) _pins.unpin(old);
    _pins.pin(key);
    _pinned = key;
  }

  /// Renders [key] after this frame unless that render is already running.
  /// Called whenever the preview is missing from the cache: first build, a
  /// new page or DPR, or the cache was cleared (memory pressure).
  void _requestRender(String key) {
    if (_inFlight == key) return;
    _inFlight = key;
    final cacheKey = widget.cacheKey;
    final width = _width!;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _render(key, cacheKey, width));
  }

  Future<void> _render(String key, String cacheKey, int width) async {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    // A throwing rasteriser counts as a failed render (PDF icon).
    final result = await renderLibraryPreview(container, cacheKey, width: width)
        .catchError((Object _) => null);
    if (_inFlight == key) _inFlight = null;
    if (!mounted) return;
    if (key != _key) return;
    if (result == null) {
      setState(() => _renderFailed = true);
    } else if (!ref.read(pdfLibraryPreviewCacheProvider).containsKey(key)) {
      // Cleared while this render was finishing: build again to re-request.
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = _key;
    _pin(key);
    final cached = ref.watch(pdfLibraryPreviewCacheProvider)[key];

    if (cached != null) {
      return Image.memory(
        cached,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPdfIcon(context),
      );
    }

    if (_renderFailed) return _buildPdfIcon(context);
    _requestRender(key);
    return const _LoadingIndicator();
  }

  Widget _buildPdfIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        Icons.picture_as_pdf,
        size: 48,
        color: colorScheme.error.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Image preview widget
class _ImagePreview extends StatelessWidget {
  final dynamic data;
  const _ImagePreview({required this.data});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      data,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// Loading indicator for preview
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
