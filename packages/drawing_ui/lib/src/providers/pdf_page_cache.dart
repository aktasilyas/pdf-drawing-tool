import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/services/pdf_page_renderer.dart';
import 'package:drawing_ui/src/services/pdf_render_slots.dart';

/// Cache limits - MEMORY OPTİMİZE
const int maxCachePages = 10;
const int maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB

/// Display quality used for the standard (un-zoomed) page render.
const double standardPdfQuality = 1.5;

// =============================================================================
// CACHES
// =============================================================================

/// Thumbnail cache (düşük çözünürlük - 150x200px)
final pdfThumbnailCacheProvider =
    StateProvider<Map<String, Uint8List>>((ref) => {});

/// PDF sayfa render cache (yüksek çözünürlük)
final pdfPageCacheProvider = StateProvider<Map<String, Uint8List>>((ref) => {});

// =============================================================================
// RENDER PLUMBING
// =============================================================================

/// Concurrency gate shared by page and zoom (HQ) renders.
final pdfRenderSlotsProvider =
    Provider<PdfRenderSlots>((ref) => PdfRenderSlots(maxConcurrent: 2));

/// Rasterises page [pageNumber] (1-based) of the PDF at [filePath] at
/// display [quality]. Returns PNG bytes, or `null` on failure.
typedef PdfPageRasterizer = Future<Uint8List?> Function(
  String filePath,
  int pageNumber,
  double quality,
);

/// The low-level rasteriser; receives an already resolved file path
/// (overridable in tests).
final pdfFileRasterizerProvider =
    Provider<PdfPageRasterizer>((ref) => rasterizePdfPage);

/// The rasteriser used by page and zoom renders (overridable in tests).
/// Resolves the stored path against the documents root before rasterising.
final pdfPageRasterizerProvider = Provider<PdfPageRasterizer>((ref) {
  final resolver = ref.watch(pdfPathResolverProvider);
  final rasterize = ref.watch(pdfFileRasterizerProvider);
  return (stored, pageNumber, quality) =>
      rasterize(resolver.resolve(stored), pageNumber, quality);
});

/// Default [PdfPageRasterizer] backed by pdfx; the bitmap size is capped by
/// [PDFPageRenderer.maxRenderSide].
Future<Uint8List?> rasterizePdfPage(
  String filePath,
  int pageNumber,
  double quality,
) async {
  if (!await File(filePath).exists()) {
    debugPrint('PDF file not found: $filePath');
    return null;
  }
  PdfDocument? document;
  PdfPage? page;
  try {
    document = await PdfDocument.openFile(filePath);
    page = await document.getPage(pageNumber);
    final size = PDFPageRenderer().renderSizeForDisplayQuality(
      pageWidth: page.width,
      pageHeight: page.height,
      quality: quality,
    );
    final image = await page.render(
      width: size.width,
      height: size.height,
      format: PdfPageImageFormat.png,
    );
    return image?.bytes;
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
  }
}

/// A parsed `'<filePath>|<pageNumber>'` cache key.
typedef PdfPageTarget = ({String filePath, int pageNumber});

/// Parses a `'<filePath>|<pageNumber>'` cache key; `null` if malformed.
PdfPageTarget? parsePdfCacheKey(String cacheKey) {
  final parts = cacheKey.split('|');
  if (parts.length != 2) return null;
  final pageNumber = int.tryParse(parts[1]);
  if (pageNumber == null) return null;
  return (filePath: parts[0], pageNumber: pageNumber);
}

// =============================================================================
// CACHE MANAGEMENT
// =============================================================================

/// Adds [bytes] under [cacheKey], evicting the oldest entries to respect
/// [maxCachePages] and [maxCacheSizeBytes].
void addToPdfPageCache(Ref ref, String cacheKey, Uint8List bytes) {
  final cache = ref.read(pdfPageCacheProvider);
  if (cache.containsKey(cacheKey)) return;

  // Page limit
  if (cache.length >= maxCachePages) {
    final oldestKey = cache.keys.first;
    ref.read(pdfPageCacheProvider.notifier).update((state) {
      final newState = Map<String, Uint8List>.from(state);
      newState.remove(oldestKey);
      return newState;
    });
  }

  // Size limit
  int currentSize = 0;
  for (final b in cache.values) {
    currentSize += b.lengthInBytes;
  }

  if (currentSize + bytes.lengthInBytes > maxCacheSizeBytes) {
    final keysToRemove = <String>[];
    int removedSize = 0;

    for (final entry in cache.entries) {
      keysToRemove.add(entry.key);
      removedSize += entry.value.lengthInBytes;
      if (currentSize - removedSize + bytes.lengthInBytes <=
          maxCacheSizeBytes) {
        break;
      }
    }

    ref.read(pdfPageCacheProvider.notifier).update((state) {
      final newState = Map<String, Uint8List>.from(state);
      for (final key in keysToRemove) {
        newState.remove(key);
      }
      return newState;
    });
  }

  ref.read(pdfPageCacheProvider.notifier).update((state) => {
        ...state,
        cacheKey: bytes,
      });
}

final clearPdfCacheProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(pdfPageCacheProvider.notifier).state = {};
    ref.read(pdfThumbnailCacheProvider.notifier).state = {};
  };
});

final pdfCacheSizeProvider = Provider<int>((ref) {
  final cache = ref.watch(pdfPageCacheProvider);
  int totalBytes = 0;
  for (final bytes in cache.values) {
    totalBytes += bytes.lengthInBytes;
  }
  return totalBytes;
});

final pdfCacheSizeMBProvider = Provider<double>((ref) {
  final bytes = ref.watch(pdfCacheSizeProvider);
  return bytes / (1024 * 1024);
});

final pdfCacheCountProvider = Provider<int>((ref) {
  return ref.watch(pdfPageCacheProvider).length;
});
