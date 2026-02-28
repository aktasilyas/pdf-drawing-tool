/// ElyaNotes Document Preview Widgets
///
/// Doküman önizleme widget'ları (PDF, Image preview).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';

/// Document preview widget for PDF and Image documents
class DocumentPreview extends ConsumerWidget {
  final DocumentInfo document;

  const DocumentPreview({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<core.DrawingDocument?>(
      future: _loadDocument(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingIndicator();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final doc = snapshot.data!;
        if (doc.pages.isEmpty) return const SizedBox.shrink();
        final firstPage = doc.pages.first;

        // Embedded image data (image imports)
        if (firstPage.background.pdfData != null) {
          return _ImagePreview(data: firstPage.background.pdfData!);
        }

        // Lazy-loaded PDF (render thumbnail from file path)
        if (firstPage.background.pdfFilePath != null &&
            firstPage.background.pdfPageIndex != null) {
          final cacheKey = '${firstPage.background.pdfFilePath}'
              '|${firstPage.background.pdfPageIndex}';
          return _PdfThumbnail(cacheKey: cacheKey);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<core.DrawingDocument?> _loadDocument(WidgetRef ref) async {
    try {
      final loadUseCase = ref.read(loadDocumentUseCaseProvider);
      final result = await loadUseCase(document.id);
      return result.fold((_) => null, (doc) => doc);
    } catch (_) {
      return null;
    }
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerRender());
  }

  Future<void> _triggerRender() async {
    if (!mounted) return;
    final container = ProviderScope.containerOf(context);
    final result = await renderThumbnail(container, widget.cacheKey);
    if (!mounted) return;
    if (result == null) {
      setState(() => _renderFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(pdfThumbnailCacheProvider);
    final cached = cache[widget.cacheKey];

    if (cached != null) {
      return Image.memory(
        cached,
        fit: BoxFit.cover,
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
      fit: BoxFit.cover,
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
