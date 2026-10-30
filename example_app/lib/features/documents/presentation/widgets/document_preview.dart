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

  /// Widest tile (dp) and DPR the preview must stay sharp at; mirrors the
  /// stored library preview (`libraryThumbnailPixels`).
  static const double _tileWidth = 240;
  static const double _maxDpr = 3;

  int get _width =>
      (_tileWidth * MediaQuery.devicePixelRatioOf(context).clamp(1.0, _maxDpr))
          .ceil();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerRender());
  }

  Future<void> _triggerRender() async {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context);
    final result = await renderLibraryPreview(
      container,
      widget.cacheKey,
      width: _width,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _renderFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(pdfLibraryPreviewCacheProvider);
    final cached = cache[libraryPreviewKey(widget.cacheKey, _width)];

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
