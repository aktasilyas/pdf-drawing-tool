import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';

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
      debugPrint('PDF file not found: $filePath');
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
    debugPrint('PDF render error: $e');
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
    debugPrint('PDF render error: $e');
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

/// Sayfa değiştiğinde: önce görünen sayfa, sonra adjacent prefetch.
///
/// [pdfPageIndex] is the 1-based PDF page number from
/// `page.background.pdfPageIndex`, NOT the document page index.
void prefetchOnPageChange(WidgetRef ref, int pdfPageIndex) {
  final pdfFilePath = ref.read(currentPdfFilePathProvider);
  final totalPages = ref.read(totalPdfPagesProvider);

  if (pdfFilePath == null || totalPages == 0) return;

  ref.read(visiblePdfPageProvider.notifier).state = pdfPageIndex - 1;

  final currentPage = pdfPageIndex; // already 1-based
  final currentKey = '$pdfFilePath|$currentPage';

  final cache = ref.read(pdfPageCacheProvider);

  // 1. Görünen sayfa cache'de yoksa render et
  if (!cache.containsKey(currentKey)) {
    ref.read(pdfPageRenderProvider(currentKey));
  }

  // 2. Görünen sayfa renderı bittikten SONRA adjacent prefetch (500ms gecikme)
  Future.delayed(const Duration(milliseconds: 500), () {
    _prefetchAdjacent(ref, currentPage, pdfFilePath, totalPages);
  });
}

/// Adjacent sayfaları arka planda prefetch et (±2 sayfa)
void _prefetchAdjacent(
    WidgetRef ref, int currentPage, String pdfFilePath, int totalPages) {
  final cache = ref.read(pdfPageCacheProvider);
  final slots = ref.read(pdfRenderSlotsProvider);

  // Sadece ±2 sayfa prefetch et
  final offsets = [1, -1, 2, -2];

  for (final offset in offsets) {
    final targetPage = currentPage + offset;
    if (targetPage >= 1 && targetPage <= totalPages) {
      final targetKey = '$pdfFilePath|$targetPage';

      // Cache'de yoksa ve şu an render edilmiyorsa prefetch et
      if (!cache.containsKey(targetKey) && !slots.isBusy(targetKey)) {
        ref.read(pdfPageRenderProvider(targetKey));
      }
    }
  }
}

// =============================================================================
// LEGACY SUPPORT
// =============================================================================

final pdfRenderQueueProvider = Provider<_LegacyQueue>((ref) => _LegacyQueue());

class _LegacyQueue {
  void onVisiblePageChanged(int index, String path, int total) {}
  void clear() {}
}

// Legacy - kullanılmıyor ama import hataları önlemek için
class BulkPrefetchRequest {
  final String pdfFilePath;
  final List<int> pageNumbers;
  final int awaitFirstN;

  const BulkPrefetchRequest({
    required this.pdfFilePath,
    required this.pageNumbers,
    this.awaitFirstN = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BulkPrefetchRequest && pdfFilePath == other.pdfFilePath;

  @override
  int get hashCode => pdfFilePath.hashCode;
}

final pdfBulkPrefetchProvider =
    FutureProvider.family<void, BulkPrefetchRequest>((ref, request) async {
  // DEVRE DIŞI
  return;
});
