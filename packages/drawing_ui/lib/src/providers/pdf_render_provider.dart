import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:drawing_ui/src/services/pdf_page_renderer.dart';

/// Cache limits - MEMORY OPTİMİZE
const int maxCachePages = 10;
const int maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB

/// Maximum concurrent PDF render operations
const int _maxConcurrentRenders = 2;

// =============================================================================
// CACHES
// =============================================================================

/// Thumbnail cache (düşük çözünürlük - 150x200px)
final pdfThumbnailCacheProvider =
    StateProvider<Map<String, Uint8List>>((ref) => {});

/// PDF sayfa render cache (yüksek çözünürlük)
final pdfPageCacheProvider = StateProvider<Map<String, Uint8List>>((ref) => {});

// =============================================================================
// STATE PROVIDERS
// =============================================================================

/// Görünen PDF sayfa index'i (0-based)
final visiblePdfPageProvider = StateProvider<int?>((ref) => null);

/// Aktif PDF dosya yolu
final currentPdfFilePathProvider = StateProvider<String?>((ref) => null);

/// Toplam PDF sayfa sayısı
final totalPdfPagesProvider = StateProvider<int>((ref) => 0);

/// Zoom'a göre kalite hesapla
double getQualityForZoom(double zoom) {
  if (zoom <= 1.3) return 1.5;   // Normal görünüm
  if (zoom <= 2.0) return 2.0;   // Orta zoom
  return 2.5;                     // Max zoom (3.0 yerine 2.5 - daha hızlı)
}

/// Kaliteli cache key oluştur
String getQualityCacheKey(String baseCacheKey, double quality) {
  return '${baseCacheKey}@${quality}x';
}

// =============================================================================
// ZOOM-BASED HQ RENDER PROVIDER
// =============================================================================

/// Zoom-based HQ render trigger
/// Bu provider'a zoom değeri yazılınca otomatik HQ render başlar
final zoomBasedRenderProvider = StateNotifierProvider<ZoomBasedRenderNotifier, double>((ref) {
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
    
    // Zaten var mı?
    final cache = ref.read(pdfPageCacheProvider);
    if (cache.containsKey(qualityKey)) {
      return;
    }
    
    // Zaten render ediliyor mu?
    if (_currentlyRendering.contains(qualityKey)) {
      return;
    }
    
    _currentlyRendering.add(qualityKey);

    if (!_canStartRender) return;
    _activeRenderCount++;

    PdfDocument? document;
    PdfPage? page;
    try {
      final parts = cacheKey.split('|');
      if (parts.length != 2) return;

      final filePath = parts[0];
      final pageNumber = int.tryParse(parts[1]);
      if (pageNumber == null) return;

      // Check file existence before opening
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('PDF file not found: $filePath');
        return;
      }

      document = await PdfDocument.openFile(filePath);
      page = await document.getPage(pageNumber);

      final renderer = PDFPageRenderer();
      final renderOptions = PDFRenderOptions(
        quality: quality >= 2.5 ? RenderQuality.high : RenderQuality.medium,
        devicePixelRatio: quality,
      );

      final dpi = renderer.getRecommendedDPI(
        renderOptions.quality,
        renderOptions.devicePixelRatio,
      );

      final width = renderer.calculateRenderWidth(pageWidth: page.width, dpi: dpi);
      final height = renderer.calculateRenderHeight(pageHeight: page.height, dpi: dpi);

      final pageImage = await page.render(
        width: width,
        height: height,
        format: PdfPageImageFormat.png,
      );

      if (pageImage?.bytes != null) {
        final bytes = pageImage!.bytes!;

        // Cache'e ekle (boyut limitli)
        _addToCache(ref, qualityKey, bytes);

        // Aynı sayfanın eski kalitelerini temizle
        ref.read(pdfPageCacheProvider.notifier).update((state) {
          final newState = Map<String, Uint8List>.from(state);
          final keysToRemove = <String>[];
          for (final key in newState.keys) {
            if (key.startsWith(cacheKey) && key != qualityKey && key.contains('@')) {
              keysToRemove.add(key);
            }
          }
          for (final key in keysToRemove) {
            newState.remove(key);
          }
          return newState;
        });

        state = quality;
      }
    } catch (e) {
      debugPrint('PDF render error: $e');
    } finally {
      try { await page?.close(); } catch (_) {}
      try { await document?.close(); } catch (_) {}
      _currentlyRendering.remove(qualityKey);
      _activeRenderCount--;
    }
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// =============================================================================
// DUPLICATE RENDER PREVENTION
// =============================================================================

final _currentlyRendering = <String>{};

/// Tracks active render count for concurrency limiting
int _activeRenderCount = 0;

/// Whether a new render can start (respects concurrency limit)
bool get _canStartRender => _activeRenderCount < _maxConcurrentRenders;

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
  if (_currentlyRendering.contains(thumbKey)) {
    return null;
  }
  _currentlyRendering.add(thumbKey);

  PdfDocument? document;
  PdfPage? page;
  try {
    final parts = cacheKey.split('|');
    if (parts.length != 2) return null;

    final filePath = parts[0];
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
      final bytes = pageImage!.bytes!;
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
    try { await page?.close(); } catch (_) {}
    try { await document?.close(); } catch (_) {}
    _currentlyRendering.remove(thumbKey);
  }
}

// =============================================================================
// SINGLE PAGE RENDER
// =============================================================================

Future<Uint8List?> _renderSinglePage(Ref ref, String cacheKey) async {
  // 1. Cache check
  final cache = ref.read(pdfPageCacheProvider);
  if (cache.containsKey(cacheKey)) {
    return cache[cacheKey];
  }

  // 2. Already rendering? Wait briefly
  if (_currentlyRendering.contains(cacheKey)) {
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final updatedCache = ref.read(pdfPageCacheProvider);
      if (updatedCache.containsKey(cacheKey)) {
        return updatedCache[cacheKey];
      }
      if (!_currentlyRendering.contains(cacheKey)) {
        break;
      }
    }
  }

  // 3. Concurrency limit check
  if (!_canStartRender) {
    // Kuyrukta bekle - max 3 saniye
    for (var i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_canStartRender) break;
      // Cache dolmuş olabilir
      final retryCache = ref.read(pdfPageCacheProvider);
      if (retryCache.containsKey(cacheKey)) return retryCache[cacheKey];
    }
    if (!_canStartRender) return null;
  }

  // 4. Start render
  _currentlyRendering.add(cacheKey);
  _activeRenderCount++;

  PdfDocument? document;
  PdfPage? page;
  try {
    final parts = cacheKey.split('|');
    if (parts.length != 2) return null;

    final filePath = parts[0];
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

    final renderer = PDFPageRenderer();
    const renderOptions = PDFRenderOptions(
      quality: RenderQuality.medium,
      devicePixelRatio: 1.5,
    );

    final dpi = renderer.getRecommendedDPI(
      renderOptions.quality,
      renderOptions.devicePixelRatio,
    );

    final width =
        renderer.calculateRenderWidth(pageWidth: page.width, dpi: dpi);
    final height =
        renderer.calculateRenderHeight(pageHeight: page.height, dpi: dpi);

    final pageImage = await page.render(
      width: width,
      height: height,
      format: PdfPageImageFormat.png,
    );

    if (pageImage?.bytes != null) {
      final bytes = pageImage!.bytes!;
      _addToCache(ref, cacheKey, bytes);
      return bytes;
    }

    return null;
  } catch (e) {
    debugPrint('PDF render error: $e');
    return null;
  } finally {
    try { await page?.close(); } catch (_) {}
    try { await document?.close(); } catch (_) {}
    _currentlyRendering.remove(cacheKey);
    _activeRenderCount--;
  }
}

// =============================================================================
// PDF PAGE RENDER PROVIDER
// =============================================================================

final pdfPageRenderProvider =
    FutureProvider.family<Uint8List?, String>((ref, cacheKey) async {
  final cache = ref.read(pdfPageCacheProvider);
  if (cache.containsKey(cacheKey)) {
    return cache[cacheKey];
  }

  return await _renderSinglePage(ref, cacheKey);
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
void _prefetchAdjacent(WidgetRef ref, int currentPage, String pdfFilePath, int totalPages) {
  final cache = ref.read(pdfPageCacheProvider);
  
  // Sadece ±2 sayfa prefetch et
  final offsets = [1, -1, 2, -2];
  
  for (final offset in offsets) {
    final targetPage = currentPage + offset;
    if (targetPage >= 1 && targetPage <= totalPages) {
      final targetKey = '$pdfFilePath|$targetPage';
      
      // Cache'de yoksa ve şu an render edilmiyorsa prefetch et
      if (!cache.containsKey(targetKey) && !_currentlyRendering.contains(targetKey)) {
        ref.read(pdfPageRenderProvider(targetKey));
      }
    }
  }
}

// =============================================================================
// CACHE MANAGEMENT
// =============================================================================

void _addToCache(Ref ref, String cacheKey, Uint8List bytes) {
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
