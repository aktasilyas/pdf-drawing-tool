import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/providers/pending_selection_image_provider.dart';
import 'package:drawing_ui/src/services/selection_capture_service.dart';
import 'package:drawing_ui/src/services/selection_image_sink.dart';
import 'package:drawing_ui/src/widgets/screenshot_preview_dialog.dart';

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

/// Result of a screenshot attempt; the UI maps it to localized feedback.
enum SelectionScreenshotOutcome {
  captureFailed,
  savedAndCopied,
  saved,
  copied,
  saveFailed,
}

/// Maps a [SelectionImageSaveResult] to a [SelectionScreenshotOutcome].
SelectionScreenshotOutcome screenshotOutcomeFor(
        SelectionImageSaveResult result) =>
    switch (result) {
      SelectionImageSaveResult.savedAndCopied =>
        SelectionScreenshotOutcome.savedAndCopied,
      SelectionImageSaveResult.saved => SelectionScreenshotOutcome.saved,
      SelectionImageSaveResult.copied => SelectionScreenshotOutcome.copied,
      SelectionImageSaveResult.failed => SelectionScreenshotOutcome.saveFailed,
    };

/// Captures [selection], previews it and saves it. Returns the outcome, or
/// null when cancelled or the context is gone. Shows no feedback itself.
Future<SelectionScreenshotOutcome?> screenshotSelection(
  WidgetRef ref,
  Selection selection,
  ImageCacheManager? cacheManager,
  BuildContext? context,
) async {
  if (cacheManager == null) return null;

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
      return SelectionScreenshotOutcome.captureFailed;
    }

    if (context == null || !context.mounted) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ScreenshotPreviewDialog(bytes: bytes),
    );
    if (confirmed != true) return null;

    final result = await saveSelectionImage(sink, bytes);
    return screenshotOutcomeFor(result);
  } catch (e) {
    DrawingLog.e('Screenshot selection failed: $e');
    return SelectionScreenshotOutcome.captureFailed;
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
    DrawingLog.e('Capture for AI failed: $e');
  }

  aiCallback();
}
