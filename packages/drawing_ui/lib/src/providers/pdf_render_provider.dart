import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:drawing_ui/src/services/pdf_page_renderer.dart';

/// Cache limits
const int maxCachePages = 20; // Maximum 20 pages in cache
const int maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB

/// PDF sayfa render cache
/// Key: "filePath|pageNumber" → Value: rendered bytes
final pdfPageCacheProvider = StateProvider<Map<String, Uint8List>>((ref) => {});

/// PDF sayfa render provider (lazy loading)
/// 
/// Cache key format: "pdfFilePath|pageNumber"
/// 
/// Örnek: "/data/user/0/.../pdfs/pdf_123456.pdf|5"
final pdfPageRenderProvider = FutureProvider.family<Uint8List?, String>((ref, cacheKey) async {
  // Cache'de var mı kontrol et
  final cache = ref.read(pdfPageCacheProvider);
  if (cache.containsKey(cacheKey)) {
    debugPrint('✅ PDF cache HIT: $cacheKey');
    return cache[cacheKey];
  }
  
  debugPrint('🔄 PDF cache MISS, rendering: $cacheKey');
  
  // Parse cache key: "filePath|pageNumber"
  final parts = cacheKey.split('|');
  if (parts.length != 2) {
    debugPrint('❌ Invalid cache key format: $cacheKey');
    return null;
  }
  
  final filePath = parts[0];
  final pageNumber = int.tryParse(parts[1]);
  if (pageNumber == null) {
    debugPrint('❌ Invalid page number in cache key: ${parts[1]}');
    return null;
  }
  
  try {
    // PDF dosyasını aç
    final document = await PdfDocument.openFile(filePath);
    
    // Sayfayı al
    final page = await document.getPage(pageNumber);
    
    // Yüksek kalite render
    final renderer = PDFPageRenderer();
    const renderOptions = PDFRenderOptions(
      quality: RenderQuality.high,
      devicePixelRatio: 1.5,
    );
    
    final dpi = renderer.getRecommendedDPI(
      renderOptions.quality,
      renderOptions.devicePixelRatio,
    );
    
    final width = renderer.calculateRenderWidth(
      pageWidth: page.width,
      dpi: dpi,
    );
    
    final height = renderer.calculateRenderHeight(
      pageHeight: page.height,
      dpi: dpi,
    );
    
    debugPrint('📄 Rendering PDF page $pageNumber: ${width.toInt()}x${height.toInt()}px');
    
    final pageImage = await page.render(
      width: width,
      height: height,
      format: PdfPageImageFormat.png,
    );
    
    await page.close();
    await document.close();
    
    if (pageImage != null && pageImage.bytes != null) {
      final bytes = pageImage.bytes!;
      debugPrint('✅ PDF page $pageNumber rendered: ${bytes.lengthInBytes} bytes');
      
      // Cache'e LRU mantığı ile ekle
      _addToCache(ref, cacheKey, bytes);
      
      return bytes;
    }
    
    debugPrint('⚠️ PDF render returned null for page $pageNumber');
    return null;
  } catch (e, stackTrace) {
    debugPrint('❌ PDF render error: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
});

/// Cache temizleme provider
final clearPdfCacheProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(pdfPageCacheProvider.notifier).state = {};
    debugPrint('🗑️ PDF cache cleared');
  };
});

/// Cache boyutu bilgisi
final pdfCacheSizeProvider = Provider<int>((ref) {
  final cache = ref.watch(pdfPageCacheProvider);
  int totalBytes = 0;
  for (final bytes in cache.values) {
    totalBytes += bytes.lengthInBytes;
  }
  return totalBytes;
});

/// Cache boyutu MB cinsinden
final pdfCacheSizeMBProvider = Provider<double>((ref) {
  final bytes = ref.watch(pdfCacheSizeProvider);
  return bytes / (1024 * 1024);
});

/// LRU Cache ekle (private helper)
void _addToCache(Ref ref, String cacheKey, Uint8List bytes) {
  final cache = ref.read(pdfPageCacheProvider);
  
  // Sayfa limiti kontrolü
  if (cache.length >= maxCachePages && !cache.containsKey(cacheKey)) {
    // En eski (first) entry'yi sil (Map'te insertion order korunur)
    final oldestKey = cache.keys.first;
    final oldestValue = cache[oldestKey];
    if (oldestValue != null) {
      final evictedBytes = oldestValue.lengthInBytes;
      
      ref.read(pdfPageCacheProvider.notifier).update((state) {
        final newState = Map<String, Uint8List>.from(state);
        newState.remove(oldestKey);
        return newState;
      });
      
      debugPrint('🗑️ Cache evicted (page limit): $oldestKey (${(evictedBytes / 1024).toStringAsFixed(1)} KB)');
    }
  }
  
  // Boyut limiti kontrolü
  int currentSize = 0;
  for (final b in cache.values) {
    currentSize += b.lengthInBytes;
  }
  
  final newSize = currentSize + bytes.lengthInBytes;
  if (newSize > maxCacheSizeBytes && !cache.containsKey(cacheKey)) {
    // Boyut limiti aşılacak, en eski entry'leri sil
    final keysToRemove = <String>[];
    int removedSize = 0;
    
    for (final entry in cache.entries) {
      keysToRemove.add(entry.key);
      removedSize += entry.value.lengthInBytes;
      
      // Yeterince yer açıldı mı?
      if (currentSize - removedSize + bytes.lengthInBytes <= maxCacheSizeBytes) {
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
    
    debugPrint('🗑️ Cache evicted (size limit): ${keysToRemove.length} pages (${(removedSize / 1024 / 1024).toStringAsFixed(2)} MB)');
  }
  
  // Yeni entry'yi ekle
  ref.read(pdfPageCacheProvider.notifier).update((state) => {
    ...state,
    cacheKey: bytes,
  });
  
  debugPrint('📦 Cache added: $cacheKey (${cache.length + 1} pages, ${((currentSize + bytes.lengthInBytes) / 1024 / 1024).toStringAsFixed(2)} MB)');
}
