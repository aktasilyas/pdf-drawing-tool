import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';

/// Zoom'a göre kalite hesapla
double getQualityForZoom(double zoom) {
  if (zoom <= 1.3) return 1.5; // Normal görünüm
  if (zoom <= 2.0) return 2.0; // Orta zoom
  return 2.5; // Max zoom (3.0 yerine 2.5 - daha hızlı)
}

/// Kaliteli cache key oluştur
String getQualityCacheKey(String baseCacheKey, double quality) {
  return '$baseCacheKey@${quality}x';
}

/// Quality variants of [cacheKey] in [keys] other than [qualityKey].
///
/// Matches the exact `'$cacheKey@'` prefix, so `path|1` never matches
/// `path|10@2.0x`.
List<String> staleQualityKeys(
  Iterable<String> keys,
  String cacheKey,
  String qualityKey,
) {
  final prefix = '$cacheKey@';
  return [
    for (final key in keys)
      if (key.startsWith(prefix) && key != qualityKey) key,
  ];
}

// =============================================================================
// ZOOM-BASED HQ RENDER PROVIDER
// =============================================================================

/// Zoom-based HQ render trigger
/// Bu provider'a zoom değeri yazılınca otomatik HQ render başlar
final zoomBasedRenderProvider =
    StateNotifierProvider<ZoomBasedRenderNotifier, double>((ref) {
  return ZoomBasedRenderNotifier(ref);
});

class ZoomBasedRenderNotifier extends StateNotifier<double> {
  final Ref ref;
  Timer? _debounceTimer;

  ZoomBasedRenderNotifier(this.ref) : super(1.0);

  void onZoomChanged(double zoom, String? cacheKey) {
    state = zoom;

    if (cacheKey == null || zoom <= 1.2) return;

    // Debounce - 150ms bekle
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _renderHighQuality(cacheKey, zoom);
    });
  }

  Future<void> _renderHighQuality(String cacheKey, double zoom) async {
    final quality = getQualityForZoom(zoom);
    final qualityKey = getQualityCacheKey(cacheKey, quality);

    if (ref.read(pdfPageCacheProvider).containsKey(qualityKey)) return;

    final target = parsePdfCacheKey(cacheKey);
    if (target == null) return;

    final slots = ref.read(pdfRenderSlotsProvider);
    // Waits for a free slot; false = this quality is already being rendered.
    if (!await slots.acquire(qualityKey)) return;
    try {
      if (!mounted) return;
      if (ref.read(pdfPageCacheProvider).containsKey(qualityKey)) return;

      final bytes = await ref.read(pdfPageRasterizerProvider)(
        target.filePath,
        target.pageNumber,
        quality,
      );
      if (bytes == null || !mounted) return;

      addToPdfPageCache(ref, qualityKey, bytes);

      // Aynı sayfanın eski kalitelerini temizle
      ref.read(pdfPageCacheProvider.notifier).update((state) {
        final stale = staleQualityKeys(state.keys, cacheKey, qualityKey);
        if (stale.isEmpty) return state;
        return Map<String, Uint8List>.from(state)
          ..removeWhere((key, _) => stale.contains(key));
      });

      state = quality;
    } catch (e) {
      DrawingLog.e('PDF render error: $e');
    } finally {
      slots.release(qualityKey);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
