import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'package:drawing_ui/src/providers/pdf_adjacent_prefetch.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';

export 'package:drawing_ui/src/providers/pdf_adjacent_prefetch.dart';
export 'package:drawing_ui/src/providers/pdf_page_cache.dart';
export 'package:drawing_ui/src/providers/pdf_zoom_render_provider.dart';

// =============================================================================
// STATE PROVIDERS
// =============================================================================

/// Görünen PDF sayfa index'i (0-based)
final visiblePdfPageProvider = StateProvider<int?>((ref) => null);

/// Aktif PDF dosya yolu
final currentPdfFilePathProvider = StateProvider<String?>((ref) => null);

/// Toplam PDF sayfa sayısı
final totalPdfPagesProvider = StateProvider<int>((ref) => 0);

/// Thumbnail renders in flight (not limited by the page render slots).
final _thumbnailsRendering = <String>{};

// =============================================================================
// THUMBNAIL RENDER (Low resolution)
// =============================================================================

Future<Uint8List?> renderThumbnail(
    ProviderContainer container, String cacheKey) async {
  final cache = container.read(pdfThumbnailCacheProvider);
  if (cache.containsKey(cacheKey)) {
    return cache[cacheKey];
  }

  final thumbKey = 'thumb_$cacheKey';
  if (_thumbnailsRendering.contains(thumbKey)) {
    return null;
  }
  _thumbnailsRendering.add(thumbKey);

  PdfDocument? document;
  PdfPage? page;
  try {
    final parts = cacheKey.split('|');
    if (parts.length != 2) return null;

    final filePath = container.read(pdfPathResolverProvider).resolve(parts[0]);
    final pageNumber = int.tryParse(parts[1]);
    if (pageNumber == null) return null;

    // Check file existence before opening
    final file = File(filePath);
    if (!await file.exists()) {
      DrawingLog.w('PDF file not found: $filePath');
      return null;
    }

    document = await PdfDocument.openFile(filePath);
    page = await document.getPage(pageNumber);

    final aspectRatio = page.width / page.height;
    final thumbWidth = aspectRatio > 1 ? 120.0 : 100.0;
    final thumbHeight = thumbWidth / aspectRatio;

    final pageImage = await page.render(
      width: thumbWidth,
      height: thumbHeight,
      format: PdfPageImageFormat.png,
    );

    if (pageImage?.bytes != null) {
      final bytes = pageImage!.bytes;
      container.read(pdfThumbnailCacheProvider.notifier).update((state) {
        final newState = Map<String, Uint8List>.from(state);
        if (newState.length >= 50) {
          newState.remove(newState.keys.first);
        }
        newState[cacheKey] = bytes;
        return newState;
      });
      return bytes;
    }
    return null;
  } catch (e) {
    DrawingLog.e('PDF render error: $e');
    return null;
  } finally {
    try {
      await page?.close();
    } catch (_) {}
    try {
      await document?.close();
    } catch (_) {}
    _thumbnailsRendering.remove(thumbKey);
  }
}

// =============================================================================
// SINGLE PAGE RENDER
// =============================================================================

Future<Uint8List?> _renderSinglePage(Ref ref, String cacheKey) async {
  final cached = ref.read(pdfPageCacheProvider)[cacheKey];
  if (cached != null) return cached;

  final slots = ref.read(pdfRenderSlotsProvider);
  // Waits (no timeout) for a free slot, so a busy queue never yields null.
  if (!await slots.acquire(cacheKey)) {
    // Same page already in flight: reuse its result.
    await slots.whenIdle(cacheKey);
    return ref.read(pdfPageCacheProvider)[cacheKey];
  }
  try {
    final hit = ref.read(pdfPageCacheProvider)[cacheKey];
    if (hit != null) return hit;

    final target = parsePdfCacheKey(cacheKey);
    if (target == null) return null;

    final bytes = await ref.read(pdfPageRasterizerProvider)(
      target.filePath,
      target.pageNumber,
      standardPdfQuality,
    );
    if (bytes != null) addToPdfPageCache(ref, cacheKey, bytes);
    return bytes;
  } catch (e) {
    DrawingLog.e('PDF render error: $e');
    return null;
  } finally {
    slots.release(cacheKey);
  }
}

// =============================================================================
// PDF PAGE RENDER PROVIDER
// =============================================================================

/// Standard-quality render of one PDF page (`'<filePath>|<pageNumber>'`).
///
/// Successful results stay cached for the session. A `null` result (missing
/// file, render error) is not cached: the provider is disposed as soon as
/// nobody listens, so the next request renders again instead of showing a
/// permanent placeholder.
final pdfPageRenderProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>((ref, key) async {
  final link = ref.keepAlive();
  final bytes = await _renderSinglePage(ref, key);
  // Close after the value is delivered (next event-loop turn), so the
  // result still reaches the current listeners before disposal.
  if (bytes == null) Future<void>(link.close);
  return bytes;
});

// =============================================================================
// PAGE CHANGE HANDLER
// =============================================================================

/// Prefetches the pages around the visible PDF page after a page change
/// (see [PdfAdjacentPrefetcher]).
final pdfAdjacentPrefetchProvider = Provider<PdfAdjacentPrefetcher>(
  (ref) => createPdfAdjacentPrefetcher(
    ref,
    (key) => ref.read(pdfPageRenderProvider(key)),
  ),
);

/// On a page change: renders the visible page now, then prefetches its
/// neighbours after [PdfAdjacentPrefetcher.delay].
///
/// [pdfPageIndex] is the 1-based PDF page number from
/// `page.background.pdfPageIndex`, NOT the document page index. [ref] is only
/// used synchronously; the delayed prefetch runs on the provider's own ref.
void prefetchOnPageChange(WidgetRef ref, int pdfPageIndex) {
  final pdfFilePath = ref.read(currentPdfFilePathProvider);
  final totalPages = ref.read(totalPdfPagesProvider);

  if (pdfFilePath == null || totalPages == 0) return;

  ref.read(visiblePdfPageProvider.notifier).state = pdfPageIndex - 1;

  // 1. The visible page first, unless it is cached.
  final currentKey = '$pdfFilePath|$pdfPageIndex';
  if (!ref.read(pdfPageCacheProvider).containsKey(currentKey)) {
    ref.read(pdfPageRenderProvider(currentKey));
  }

  // 2. Its neighbours once it had a head start.
  ref.read(pdfAdjacentPrefetchProvider).schedule(
        pdfFilePath: pdfFilePath,
        page: pdfPageIndex,
        totalPages: totalPages,
      );
}
