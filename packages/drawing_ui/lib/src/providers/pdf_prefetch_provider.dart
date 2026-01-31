import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// PDF Prefetching stratejisi
class PrefetchStrategy {
  /// Şu anki sayfadan önce kaç sayfa prefetch edilecek
  final int pagesBefore;

  /// Şu anki sayfadan sonra kaç sayfa prefetch edilecek
  final int pagesAfter;

  const PrefetchStrategy({
    this.pagesBefore = 0, // DEVRE DIŞI
    this.pagesAfter = 0, // DEVRE DIŞI
  });

  const PrefetchStrategy.aggressive()
      : pagesBefore = 0, // DEVRE DIŞI
        pagesAfter = 0; // DEVRE DIŞI

  const PrefetchStrategy.conservative()
      : pagesBefore = 0, // DEVRE DIŞI
        pagesAfter = 0; // DEVRE DIŞI
}

/// PDF Prefetch Manager
///
/// NOT: Prefetch DEVRE DIŞI - performans sorunlarına neden oluyordu.
/// Sadece görünen sayfa render edilir.
class PDFPrefetchManager {
  final Ref ref;
  final PrefetchStrategy strategy;

  PDFPrefetchManager(
    this.ref, {
    this.strategy = const PrefetchStrategy(),
  });

  /// Prefetch DEVRE DIŞI
  void prefetchAround({
    required int currentPageIndex,
    required List<Page> allPages,
  }) {
    // ❌ PREFETCH DEVRE DIŞI - Performans sorunu çözülene kadar
    // Sadece görünen sayfa DrawingCanvas tarafından render edilir
    return;
  }

  /// Tek bir sayfayı arka planda prefetch et
  // ignore: unused_element
  Future<void> _prefetchPage(String cacheKey) async {
    // ❌ DEVRE DIŞI
    return;
  }
}

/// Prefetch manager provider
final pdfPrefetchManagerProvider = Provider<PDFPrefetchManager>((ref) {
  return PDFPrefetchManager(
    ref,
    strategy: const PrefetchStrategy(), // Prefetch devre dışı
  );
});

/// Current page watcher - DEVRE DIŞI
class PDFPrefetchNotifier extends StateNotifier<int> {
  final Ref ref;

  PDFPrefetchNotifier(this.ref) : super(0);

  void onPageChanged(int pageIndex, List<Page> allPages) {
    // ❌ PREFETCH DEVRE DIŞI
    state = pageIndex;
    // Prefetch manager çağrılmıyor
  }
}

final pdfPrefetchNotifierProvider =
    StateNotifierProvider<PDFPrefetchNotifier, int>((ref) {
  return PDFPrefetchNotifier(ref);
});
