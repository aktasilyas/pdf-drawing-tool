/// StarNote Document Preview Widgets
///
/// Doküman önizleme widget'ları (PDF, Image preview).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;

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

        // Image preview
        if (firstPage.background.pdfData != null) {
          return _ImagePreview(data: firstPage.background.pdfData!);
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
