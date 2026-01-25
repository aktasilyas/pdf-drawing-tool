import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'pdf_render_provider.dart';

/// PDF Prefetching stratejisi
class PrefetchStrategy {
  /// Şu anki sayfadan önce kaç sayfa prefetch edilecek
  final int pagesBefore;
  
  /// Şu anki sayfadan sonra kaç sayfa prefetch edilecek
  final int pagesAfter;
  
  const PrefetchStrategy({
    this.pagesBefore = 1,
    this.pagesAfter = 3,
  });
  
  const PrefetchStrategy.aggressive()
      : pagesBefore = 2,
        pagesAfter = 5;
  
  const PrefetchStrategy.conservative()
      : pagesBefore = 1,
        pagesAfter = 2;
}

/// PDF Prefetch Manager
/// 
/// Mevcut sayfanın etrafındaki sayfaları arka planda yükler.
/// Kullanıcı deneyimini optimize eder.
class PDFPrefetchManager {
  final Ref ref;
  final PrefetchStrategy strategy;
  
  PDFPrefetchManager(this.ref, {
    this.strategy = const PrefetchStrategy(),
  });
  
  /// Verilen sayfa etrafındaki sayfaları prefetch et
  void prefetchAround({
    required int currentPageIndex,
    required List<Page> allPages,
  }) {
    final totalPages = allPages.length;
    
    // Prefetch edilecek sayfa index'lerini hesapla
    final startIndex = (currentPageIndex - strategy.pagesBefore).clamp(0, totalPages - 1);
    final endIndex = (currentPageIndex + strategy.pagesAfter).clamp(0, totalPages - 1);
    
    debugPrint('📦 Prefetching pages: $startIndex to $endIndex (current: $currentPageIndex)');
    
    for (int i = startIndex; i <= endIndex; i++) {
      if (i == currentPageIndex) continue; // Mevcut sayfa zaten yükleniyor
      
      final page = allPages[i];
      if (page.background.type == BackgroundType.pdf &&
          page.background.pdfFilePath != null &&
          page.background.pdfPageIndex != null) {
        
        final cacheKey = '${page.background.pdfFilePath}|${page.background.pdfPageIndex}';
        
        // Cache'de var mı kontrol et
        final cache = ref.read(pdfPageCacheProvider);
        if (cache.containsKey(cacheKey)) {
          debugPrint('✅ Page $i already cached, skipping prefetch');
          continue;
        }
        
        // Arka planda render et (await etme - fire and forget)
        debugPrint('⚡ Prefetching page $i in background');
        _prefetchPage(cacheKey);
      }
    }
  }
  
  /// Tek bir sayfayı arka planda prefetch et
  Future<void> _prefetchPage(String cacheKey) async {
    try {
      // Provider'ı tetikle (sonucu beklemeden)
      ref.read(pdfPageRenderProvider(cacheKey));
    } catch (e) {
      debugPrint('⚠️ Prefetch error for $cacheKey: $e');
    }
  }
}

/// Prefetch manager provider
final pdfPrefetchManagerProvider = Provider<PDFPrefetchManager>((ref) {
  return PDFPrefetchManager(
    ref,
    strategy: const PrefetchStrategy.aggressive(), // Agresif prefetch
  );
});

/// Current page watcher - sayfa değiştiğinde prefetch tetikle
class PDFPrefetchNotifier extends StateNotifier<int> {
  final Ref ref;
  
  PDFPrefetchNotifier(this.ref) : super(0);
  
  void onPageChanged(int pageIndex, List<Page> allPages) {
    if (state != pageIndex) {
      state = pageIndex;
      
      // Prefetch manager'ı tetikle
      final manager = ref.read(pdfPrefetchManagerProvider);
      manager.prefetchAround(
        currentPageIndex: pageIndex,
        allPages: allPages,
      );
    }
  }
}

final pdfPrefetchNotifierProvider = StateNotifierProvider<PDFPrefetchNotifier, int>((ref) {
  return PDFPrefetchNotifier(ref);
});
