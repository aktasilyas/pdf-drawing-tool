import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/providers/pending_selection_image_provider.dart';
import 'package:drawing_ui/src/services/selection_capture_service.dart';
import 'package:drawing_ui/src/widgets/screenshot_preview_dialog.dart';
import 'package:drawing_ui/src/services/selection_image_sink.dart';

// Selection capture actions: screenshot and "ask AI about this area".

Uint8List? _pdfBytesFor(WidgetRef ref, PageBackground? background) {
  if (background?.type != BackgroundType.pdf) return null;
  if (background!.pdfData != null) return background.pdfData;
  if (background.pdfFilePath != null && background.pdfPageIndex != null) {
    final cacheKey = '${background.pdfFilePath}|${background.pdfPageIndex}';
    return ref.read(pdfPageCacheProvider)[cacheKey];
  }
  return null;
}

Future<void> screenshotSelection(
  WidgetRef ref,
  Selection selection,
  ImageCacheManager? cacheManager,
  BuildContext? context,
) async {
  if (cacheManager == null) return;

  try {
    final document = ref.read(documentProvider);
    final sink = ref.read(selectionImageSinkProvider);
    final layer = document.layers[document.activeLayerIndex];

    // Get current page background and size for screenshot rendering
    final currentPage = document.currentPage;
    final background = currentPage?.background;
    final pageSz = currentPage != null
        ? Size(currentPage.size.width, currentPage.size.height)
        : null;

    // Get PDF image bytes from cache if PDF background
    final pdfImageBytes = _pdfBytesFor(ref, background);

    final bytes = await SelectionCaptureService.captureSelection(
      selection: selection,
      layer: layer,
      cacheManager: cacheManager,
      background: background,
      pdfImageBytes: pdfImageBytes,
      pageSize: pageSz,
    );
    if (bytes == null) {
      showSnackBar(context, 'Ekran resmi oluşturulamadı');
      return;
    }

    if (context == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ScreenshotPreviewDialog(bytes: bytes),
    );
    if (confirmed != true) return;

    final result = await saveSelectionImage(sink, bytes);
    if (!context.mounted) return;
    showSnackBar(context, selectionImageSaveMessage(result));
  } catch (e) {
    debugPrint('Screenshot selection failed: $e');
    showSnackBar(context, 'Ekran resmi oluşturulamadı');
  }
}

Future<void> captureAndOpenAI(
  WidgetRef ref,
  Selection selection,
  ImageCacheManager? cacheManager,
  VoidCallback aiCallback,
) async {
  // Skip capture only when no cache or zero-area bounds (Selection.empty()).
  // Non-empty bounds should be captured even without selected elements,
  // so the user can ask AI about the selected canvas area.
  final hasBounds = selection.bounds.width > 0 && selection.bounds.height > 0;
  if (cacheManager == null || !hasBounds) {
    aiCallback();
    return;
  }

  // Read everything from ref BEFORE the async gap to avoid stale WidgetRef.
  final document = ref.read(documentProvider);
  final pendingNotifier = ref.read(pendingSelectionImageProvider.notifier);

  try {
    final layer = document.layers[document.activeLayerIndex];

    final currentPage = document.currentPage;
    final background = currentPage?.background;
    final pageSz = currentPage != null
        ? Size(currentPage.size.width, currentPage.size.height)
        : null;

    final pdfImageBytes = _pdfBytesFor(ref, background);

    final bytes = await SelectionCaptureService.captureSelection(
      selection: selection,
      layer: layer,
      cacheManager: cacheManager,
      background: background,
      pdfImageBytes: pdfImageBytes,
      pageSize: pageSz,
    );

    if (bytes != null) {
      pendingNotifier.state = bytes;
    }
  } catch (e) {
    debugPrint('Capture for AI failed: $e');
  }

  aiCallback();
}

/// Snackbar text for a [SelectionImageSaveResult].
String selectionImageSaveMessage(SelectionImageSaveResult result) =>
    switch (result) {
      SelectionImageSaveResult.savedAndCopied =>
        'Ekran resmi galeriye kaydedildi ve panoya kopyalandı',
      SelectionImageSaveResult.saved => 'Ekran resmi galeriye kaydedildi',
      SelectionImageSaveResult.copied => 'Ekran resmi panoya kopyalandı',
      SelectionImageSaveResult.failed => 'Ekran resmi kaydedilemedi',
    };

void showSnackBar(BuildContext? context, String message) {
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}
