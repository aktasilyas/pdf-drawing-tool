import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';

/// Most library previews kept in memory (each is a few hundred KB).
const int maxLibraryPreviews = 24;

/// Widest library tile (logical px) a preview must stay sharp at. Shared by
/// the PDF tile render and the stored library preview of the host app.
const double libraryPreviewTileWidth = 240;

/// Highest device pixel ratio a library preview must stay sharp at.
const double libraryPreviewMaxDpr = 3;

/// Widest library preview that is rendered, in pixels:
/// [libraryPreviewTileWidth] x [libraryPreviewMaxDpr].
const int maxLibraryPreviewWidth = 720;

/// Pixel width a library preview needs on a screen with [devicePixelRatio]
/// (clamped to 1..[libraryPreviewMaxDpr]).
int libraryPreviewWidth(double devicePixelRatio) => (libraryPreviewTileWidth *
        devicePixelRatio.clamp(1.0, libraryPreviewMaxDpr))
    .ceil();

/// Library previews by `'<width>|<filePath>|<page>'`. Separate from
/// [pdfThumbnailCacheProvider] so sidebar thumbnails stay small and cheap.
final pdfLibraryPreviewCacheProvider =
    StateProvider<Map<String, Uint8List>>((ref) => {});

/// Library preview keys shown by a mounted tile, with a count per key (two
/// tiles may show the same page). [renderLibraryPreview] never evicts a pinned
/// key, so a visible tile keeps its preview however many tiles are mounted
/// and evicted tiles cannot push each other out in a render loop.
class LibraryPreviewPins {
  final Map<String, int> _counts = {};

  /// Marks [key] as shown by one more tile.
  void pin(String key) =>
      _counts.update(key, (c) => c + 1, ifAbsent: () => 1);

  /// Marks [key] as shown by one tile less; unknown keys are ignored.
  void unpin(String key) {
    final count = _counts[key];
    if (count == null) return;
    if (count <= 1) {
      _counts.remove(key);
    } else {
      _counts[key] = count - 1;
    }
  }

  /// Whether a mounted tile shows [key].
  bool contains(String key) => _counts.containsKey(key);
}

/// The [LibraryPreviewPins] of the library tiles (not reactive).
final libraryPreviewPinsProvider =
    Provider<LibraryPreviewPins>((ref) => LibraryPreviewPins());

/// Drops every library preview (memory pressure). Mounted tiles render
/// theirs again.
final clearLibraryPreviewsProvider = Provider<void Function()>((ref) {
  return () => ref.read(pdfLibraryPreviewCacheProvider.notifier).state = {};
});

/// Renders page [pageNumber] (1-based) of the PDF at [filePath] [width] px wide.
/// Returns PNG bytes, or `null` on failure.
typedef PdfWidthRasterizer = Future<Uint8List?> Function(
  String filePath,
  int pageNumber,
  int width,
);

/// The rasteriser behind [renderLibraryPreview] (overridable in tests).
/// Receives an already resolved file path.
final pdfWidthRasterizerProvider =
    Provider<PdfWidthRasterizer>((ref) => rasterizePdfPageToWidth);

/// Cache key of a library preview rendered [width] px wide.
String libraryPreviewKey(String cacheKey, int width) => '$width|$cacheKey';

/// Renders the library tile preview of [cacheKey] (`'<filePath>|<page>'`)
/// at [width] px (capped at [maxLibraryPreviewWidth]); null on failure.
Future<Uint8List?> renderLibraryPreview(
  ProviderContainer container,
  String cacheKey, {
  required int width,
}) async {
  final px = width.clamp(1, maxLibraryPreviewWidth);
  final key = libraryPreviewKey(cacheKey, px);
  final hit = container.read(pdfLibraryPreviewCacheProvider)[key];
  if (hit != null) return hit;

  final parts = cacheKey.split('|');
  if (parts.length != 2) return null;
  final pageNumber = int.tryParse(parts[1]);
  if (pageNumber == null) return null;

  final path = container.read(pdfPathResolverProvider).resolve(parts[0]);
  final bytes =
      await container.read(pdfWidthRasterizerProvider)(path, pageNumber, px);
  if (bytes == null) return null;
  final pins = container.read(libraryPreviewPinsProvider);
  container.read(pdfLibraryPreviewCacheProvider.notifier).update((state) {
    final next = Map<String, Uint8List>.from(state);
    while (next.length >= maxLibraryPreviews) {
      final victim = _oldestUnpinned(next, pins);
      if (victim == null) break;
      next.remove(victim);
    }
    next[key] = bytes;
    return next;
  });
  return bytes;
}

String? _oldestUnpinned(
  Map<String, Uint8List> cache,
  LibraryPreviewPins pins,
) {
  for (final key in cache.keys) {
    if (!pins.contains(key)) return key;
  }
  return null;
}

/// Default [PdfWidthRasterizer] backed by pdfx.
Future<Uint8List?> rasterizePdfPageToWidth(
  String filePath,
  int pageNumber,
  int width,
) async {
  if (!await File(filePath).exists()) {
    DrawingLog.w('PDF file not found: $filePath');
    return null;
  }
  PdfDocument? document;
  PdfPage? page;
  try {
    document = await PdfDocument.openFile(filePath);
    page = await document.getPage(pageNumber);
    final height = (width * page.height / page.width).clamp(1, 2048).toDouble();
    final image = await page.render(
      width: width.toDouble(),
      height: height,
      format: PdfPageImageFormat.png,
    );
    return image?.bytes;
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
  }
}
