# 🚀 PDF PERFORMANCE İYİLEŞTİRME - CURSOR TALİMATLARI

**Branch:** `feature/pdf-performance`
**Tarih:** 26 Ocak 2025
**Öncelik:** 🔴 Kritik
**Tahmini Süre:** 3-5 gün

---

## 📋 MEVCUT DURUM ANALİZİ

### Var Olan Sistem:
- ✅ Lazy loading altyapısı (`pdfPageRenderProvider`)
- ✅ LRU Cache (20 sayfa, 50MB limit)
- ✅ PDF dosyası cihaza kaydediliyor
- ✅ Sayfa metadata'ları hemen oluşturuluyor

### Eksikler (Performans Sorunları):
- ❌ Pre-rendering YOK - Sadece görünen sayfa render ediliyor
- ❌ Priority queue YOK - Tüm render'lar aynı öncelikte
- ❌ Scroll prediction YOK - Kullanıcı yönü tahmin edilmiyor
- ❌ Multi-resolution YOK - Sadece yüksek kalite render
- ❌ Background prefetch YOK - Arka planda yükleme yok

### Sonuç:
Kullanıcı sayfa değiştirdiğinde "Yükleniyor..." görüyor ve beklemek zorunda kalıyor.

---

## 🎯 HEDEF

GoodNotes/Notability seviyesinde performans:
- Sayfa geçişi: **<100ms** (anında hissi)
- Scroll: **60 FPS** smooth
- İlk açılış: **<2 saniye** (placeholder ile)

---

## 📁 DEĞİŞİKLİK PLANI

### Faz 1: Priority-Based Render Queue (1 gün)

#### 1.1 Yeni Dosya: `packages/drawing_ui/lib/src/services/pdf_render_queue.dart`

```dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Render öncelik seviyeleri
enum RenderPriority {
  /// Şu an görünen sayfa - EN YÜKSEK
  visible(0),
  
  /// Hemen yanındaki sayfalar (current ± 1)
  adjacent(1),
  
  /// Prefetch sayfaları (current ± 2,3)
  prefetch(2),
  
  /// Thumbnail için düşük çözünürlük
  thumbnail(3),
  
  /// Arka plan yüklemesi - EN DÜŞÜK
  background(4);
  
  final int value;
  const RenderPriority(this.value);
}

/// Render isteği
class RenderRequest implements Comparable<RenderRequest> {
  final String cacheKey;
  final int pageIndex;
  final RenderPriority priority;
  final DateTime requestedAt;
  final bool isLowRes;
  
  RenderRequest({
    required this.cacheKey,
    required this.pageIndex,
    required this.priority,
    this.isLowRes = false,
  }) : requestedAt = DateTime.now();
  
  @override
  int compareTo(RenderRequest other) {
    // Önce priority'ye göre sırala
    final priorityCompare = priority.value.compareTo(other.priority.value);
    if (priorityCompare != 0) return priorityCompare;
    
    // Aynı priority ise zamana göre (FIFO)
    return requestedAt.compareTo(other.requestedAt);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenderRequest && cacheKey == other.cacheKey && isLowRes == other.isLowRes;
  
  @override
  int get hashCode => Object.hash(cacheKey, isLowRes);
}

/// PDF Render Queue - Priority based rendering
class PdfRenderQueue {
  final _queue = SplayTreeSet<RenderRequest>();
  final _inProgress = <String>{};
  final _completed = <String>{};
  
  bool _isProcessing = false;
  int _maxConcurrent = 2; // Aynı anda max 2 render
  
  /// Render işlemi için callback
  Future<void> Function(RenderRequest request)? onRender;
  
  /// Render tamamlandığında callback
  void Function(String cacheKey)? onCompleted;
  
  /// Queue'ya istek ekle
  void enqueue(RenderRequest request) {
    // Zaten tamamlandıysa skip
    if (_completed.contains(request.cacheKey)) {
      debugPrint('⏭️ Skip (already rendered): ${request.cacheKey}');
      return;
    }
    
    // Zaten queue'da veya işlemde ise skip
    if (_inProgress.contains(request.cacheKey)) {
      debugPrint('⏭️ Skip (in progress): ${request.cacheKey}');
      return;
    }
    
    // Aynı sayfa farklı priority ile varsa, yüksek priority olanı tut
    final existing = _queue.where((r) => r.cacheKey == request.cacheKey).firstOrNull;
    if (existing != null) {
      if (request.priority.value < existing.priority.value) {
        _queue.remove(existing);
        _queue.add(request);
        debugPrint('🔄 Priority upgraded: ${request.cacheKey} → ${request.priority}');
      }
      return;
    }
    
    _queue.add(request);
    debugPrint('📥 Queued: ${request.cacheKey} (${request.priority.name})');
    
    _processQueue();
  }
  
  /// Görünen sayfa değiştiğinde çağır
  void onVisiblePageChanged(int visibleIndex, String pdfFilePath, int totalPages) {
    // Eski prefetch'leri iptal et (visible olmayan ve adjacent olmayan)
    _cancelStaleRequests(visibleIndex);
    
    // Yeni istekler ekle
    // 1. Visible (current)
    _enqueueForPage(visibleIndex, pdfFilePath, RenderPriority.visible);
    
    // 2. Adjacent (±1)
    if (visibleIndex > 0) {
      _enqueueForPage(visibleIndex - 1, pdfFilePath, RenderPriority.adjacent);
    }
    if (visibleIndex < totalPages - 1) {
      _enqueueForPage(visibleIndex + 1, pdfFilePath, RenderPriority.adjacent);
    }
    
    // 3. Prefetch (±2, ±3)
    for (var offset in [2, 3]) {
      if (visibleIndex - offset >= 0) {
        _enqueueForPage(visibleIndex - offset, pdfFilePath, RenderPriority.prefetch);
      }
      if (visibleIndex + offset < totalPages) {
        _enqueueForPage(visibleIndex + offset, pdfFilePath, RenderPriority.prefetch);
      }
    }
  }
  
  /// Scroll yönüne göre prefetch
  void onScrollDirectionChanged(
    int currentIndex,
    String pdfFilePath,
    int totalPages,
    bool isScrollingForward,
  ) {
    // Scroll yönüne göre daha fazla sayfa prefetch et
    final direction = isScrollingForward ? 1 : -1;
    
    for (var i = 1; i <= 5; i++) {
      final targetIndex = currentIndex + (i * direction);
      if (targetIndex >= 0 && targetIndex < totalPages) {
        _enqueueForPage(targetIndex, pdfFilePath, RenderPriority.prefetch);
      }
    }
  }
  
  void _enqueueForPage(int pageIndex, String pdfFilePath, RenderPriority priority) {
    final cacheKey = '$pdfFilePath|${pageIndex + 1}'; // pageIndex 0-based, PDF 1-based
    enqueue(RenderRequest(
      cacheKey: cacheKey,
      pageIndex: pageIndex,
      priority: priority,
    ));
  }
  
  void _cancelStaleRequests(int visibleIndex) {
    // Visible'dan 5+ uzaktaki prefetch'leri iptal et
    _queue.removeWhere((request) {
      final distance = (request.pageIndex - visibleIndex).abs();
      if (distance > 5 && request.priority == RenderPriority.prefetch) {
        debugPrint('🚫 Cancelled stale: ${request.cacheKey}');
        return true;
      }
      return false;
    });
  }
  
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    if (onRender == null) return;
    
    _isProcessing = true;
    
    while (_queue.isNotEmpty && _inProgress.length < _maxConcurrent) {
      final request = _queue.first;
      _queue.remove(request);
      
      _inProgress.add(request.cacheKey);
      
      try {
        await onRender!(request);
        _completed.add(request.cacheKey);
        onCompleted?.call(request.cacheKey);
        debugPrint('✅ Rendered: ${request.cacheKey}');
      } catch (e) {
        debugPrint('❌ Render failed: ${request.cacheKey} - $e');
      } finally {
        _inProgress.remove(request.cacheKey);
      }
    }
    
    _isProcessing = false;
    
    // Queue'da hala istek varsa devam et
    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }
  
  /// Cache'e manuel ekleme (zaten render edilmiş sayfalar için)
  void markAsCompleted(String cacheKey) {
    _completed.add(cacheKey);
  }
  
  /// Tüm queue'yu temizle
  void clear() {
    _queue.clear();
    _inProgress.clear();
    // _completed temizleme - cache'deki veriler korunmalı
  }
  
  /// İstatistikler
  int get queueLength => _queue.length;
  int get inProgressCount => _inProgress.length;
  int get completedCount => _completed.length;
}
```

---

#### 1.2 Provider Güncelleme: `packages/drawing_ui/lib/src/providers/pdf_render_provider.dart`

```dart
// EKLENECEK: RenderQueue provider
final pdfRenderQueueProvider = Provider<PdfRenderQueue>((ref) {
  final queue = PdfRenderQueue();
  
  // Render callback'i ayarla
  queue.onRender = (request) async {
    // Mevcut render logic'i kullan
    await ref.read(pdfPageRenderProvider(request.cacheKey).future);
  };
  
  // Tamamlanınca cache'i güncelle
  queue.onCompleted = (cacheKey) {
    // Cache zaten pdfPageRenderProvider tarafından güncelleniyor
    debugPrint('🎉 Queue completed: $cacheKey');
  };
  
  ref.onDispose(() {
    queue.clear();
  });
  
  return queue;
});

// EKLENECEK: Visible page tracker
final visiblePdfPageProvider = StateProvider<int?>((ref) => null);

// EKLENECEK: PDF file path tracker  
final currentPdfFilePathProvider = StateProvider<String?>((ref) => null);

// EKLENECEK: Total pages tracker
final totalPdfPagesProvider = StateProvider<int>((ref) => 0);
```

---

### Faz 2: DrawingCanvas Entegrasyonu (1 gün)

#### 2.1 Güncelleme: `packages/drawing_ui/lib/src/canvas/drawing_canvas.dart`

`_buildPdfBackground` metodunu güncelle:

```dart
Widget _buildPdfBackground(core.Page page) {
  final background = page.background;
  
  // Eğer pdfData cache'de varsa direkt göster
  if (background.pdfData != null) {
    return Container(
      width: page.size.width,
      height: page.size.height,
      color: Colors.white,
      child: Image.memory(
        background.pdfData!,
        width: page.size.width,
        height: page.size.height,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      ),
    );
  }
  
  // Lazy load with queue
  if (background.pdfFilePath != null && background.pdfPageIndex != null) {
    final cacheKey = '${background.pdfFilePath}|${background.pdfPageIndex}';
    
    return Consumer(
      builder: (context, ref, child) {
        // Queue'ya visible olarak ekle
        final queue = ref.read(pdfRenderQueueProvider);
        final totalPages = ref.read(totalPdfPagesProvider);
        
        // Bu sayfa visible oldu, queue'yu güncelle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          queue.onVisiblePageChanged(
            background.pdfPageIndex! - 1, // 0-based index
            background.pdfFilePath!,
            totalPages,
          );
        });
        
        final renderAsync = ref.watch(pdfPageRenderProvider(cacheKey));
        
        return renderAsync.when(
          data: (bytes) {
            if (bytes != null) {
              return Container(
                width: page.size.width,
                height: page.size.height,
                color: Colors.white,
                child: Image.memory(
                  bytes,
                  width: page.size.width,
                  height: page.size.height,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              );
            }
            return _buildPdfPlaceholder(page);
          },
          loading: () => _buildPdfLoadingWithProgress(page, cacheKey, ref),
          error: (e, _) => _buildPdfError(page, e.toString()),
        );
      },
    );
  }
  
  return _buildPdfPlaceholder(page);
}

/// Loading state with queue position
Widget _buildPdfLoadingWithProgress(core.Page page, String cacheKey, WidgetRef ref) {
  final queue = ref.watch(pdfRenderQueueProvider);
  
  return Container(
    width: page.size.width,
    height: page.size.height,
    color: Colors.grey[100],
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Sayfa hazırlanıyor...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (queue.queueLength > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${queue.inProgressCount}/${queue.queueLength + queue.inProgressCount} işleniyor',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

---

### Faz 3: Page Navigator Prefetch (1 gün)

#### 3.1 Güncelleme: `packages/drawing_ui/lib/src/widgets/page_navigator.dart`

Scroll listener ekle:

```dart
class _PageNavigatorState extends State<PageNavigator> {
  final ScrollController _scrollController = ScrollController();
  int? _lastVisibleIndex;
  bool _isScrollingForward = true;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    // Scroll yönünü belirle
    final currentOffset = _scrollController.offset;
    final velocity = _scrollController.position.activity?.velocity ?? 0;
    
    _isScrollingForward = velocity >= 0;
    
    // Görünen sayfaları hesapla ve prefetch tetikle
    _triggerPrefetch();
  }
  
  void _triggerPrefetch() {
    if (!mounted) return;
    
    final context = this.context;
    final ref = ProviderScope.containerOf(context);
    
    final queue = ref.read(pdfRenderQueueProvider);
    final pdfFilePath = ref.read(currentPdfFilePathProvider);
    final totalPages = widget.pageManager.pageCount;
    final currentIndex = widget.pageManager.currentIndex;
    
    if (pdfFilePath == null) return;
    
    // Scroll yönüne göre prefetch
    queue.onScrollDirectionChanged(
      currentIndex,
      pdfFilePath,
      totalPages,
      _isScrollingForward,
    );
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  // ... rest of the widget
}
```

---

### Faz 4: Document Açılışında Initial Prefetch (0.5 gün)

#### 4.1 Güncelleme: `example_app/lib/features/documents/presentation/screens/documents_screen.dart`

`_openDocument` metodunu güncelle:

```dart
Future<void> _openDocument(String documentId) async {
  final loadUseCase = ref.read(loadDocumentUseCaseProvider);
  final result = await loadUseCase(documentId);

  result.fold(
    (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Belge açılamadı: ${failure.message}')),
        );
      }
    },
    (document) async {
      // PDF sayfaları var mı kontrol et
      final pdfPages = document.pages
          .where((p) =>
              p.background.type == core.BackgroundType.pdf &&
              p.background.pdfFilePath != null &&
              p.background.pdfPageIndex != null)
          .toList();

      if (pdfPages.isNotEmpty) {
        // PDF bilgilerini provider'lara kaydet
        final pdfFilePath = pdfPages.first.background.pdfFilePath!;
        ref.read(currentPdfFilePathProvider.notifier).state = pdfFilePath;
        ref.read(totalPdfPagesProvider.notifier).state = pdfPages.length;
        
        // Queue'yu başlat - ilk 5 sayfayı prefetch et
        final queue = ref.read(pdfRenderQueueProvider);
        queue.onVisiblePageChanged(0, pdfFilePath, pdfPages.length);
      }

      // Editor'e hemen geç (bekleme yok!)
      if (mounted) {
        context.push('/editor/$documentId');
      }
    },
  );
}
```

**ÖNEMLİ:** Mevcut "Sayfalar hazırlanıyor..." loading dialog'unu **KALDIR**. Artık gerekli değil.

---

### Faz 5: Multi-Resolution Support (Opsiyonel - 1 gün)

İleri seviye optimizasyon için:

```dart
/// Düşük çözünürlük cache (thumbnail için)
final pdfLowResCache = StateProvider<Map<String, Uint8List>>((ref) => {});

/// Önce düşük çözünürlük göster, sonra yüksek çözünürlüğe geç
Widget _buildPdfWithMultiRes(core.Page page, WidgetRef ref) {
  final cacheKey = '${page.background.pdfFilePath}|${page.background.pdfPageIndex}';
  final lowResKey = '${cacheKey}_low';
  
  final lowResCache = ref.watch(pdfLowResCache);
  final highResAsync = ref.watch(pdfPageRenderProvider(cacheKey));
  
  return highResAsync.when(
    data: (highRes) {
      if (highRes != null) {
        return Image.memory(highRes, fit: BoxFit.fill);
      }
      // Fallback to low-res if available
      final lowRes = lowResCache[lowResKey];
      if (lowRes != null) {
        return Image.memory(lowRes, fit: BoxFit.fill);
      }
      return _buildPdfPlaceholder(page);
    },
    loading: () {
      // Loading sırasında low-res göster
      final lowRes = lowResCache[lowResKey];
      if (lowRes != null) {
        return Stack(
          children: [
            Image.memory(lowRes, fit: BoxFit.fill),
            const Positioned(
              bottom: 8,
              right: 8,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        );
      }
      return _buildPdfLoading(page);
    },
    error: (e, _) => _buildPdfError(page, e.toString()),
  );
}
```

---

## 📋 UYGULAMA ADIMLARI

### Adım 1: Branch Oluştur
```bash
git checkout main
git pull
git checkout -b feature/pdf-performance
```

### Adım 2: RenderQueue Oluştur
1. `pdf_render_queue.dart` dosyasını oluştur
2. Provider'ları ekle

### Adım 3: Provider'ları Güncelle
1. `pdf_render_provider.dart` - Queue provider ekle
2. Visible page, file path, total pages provider'ları ekle

### Adım 4: DrawingCanvas Güncelle
1. `_buildPdfBackground` metodunu güncelle
2. Queue entegrasyonunu yap

### Adım 5: PageNavigator Güncelle
1. Scroll listener ekle
2. Prefetch logic'i ekle

### Adım 6: Document Açılışını Güncelle
1. Loading dialog'u kaldır
2. Initial prefetch ekle

### Adım 7: Test Et
```
Test Senaryoları:
1. 50+ sayfalık PDF aç
2. Hızlıca sayfalar arası geç
3. Page navigator'dan rastgele sayfalara atla
4. Memory kullanımını monitor et (50MB limit aşılmamalı)
5. 60 FPS scroll test
```

### Adım 8: Commit ve Push
```bash
git add .
git commit -m "feat(pdf): add priority-based render queue for faster page loading

- PdfRenderQueue: priority-based rendering with visible > adjacent > prefetch
- Scroll direction prediction for smart prefetching
- Remove blocking loading dialog on document open
- Pre-render adjacent pages automatically
- Cancel stale prefetch requests on rapid navigation"

git push origin feature/pdf-performance
```

---

## ⚠️ DİKKAT EDİLECEKLER

1. **Memory Leak:** Queue dispose edildiğinde temizlendiğinden emin ol
2. **Race Condition:** Aynı sayfa birden fazla kez render edilmemeli
3. **CPU Usage:** Max 2 concurrent render (cihazı yormamak için)
4. **Mevcut Kod:** Mevcut lazy loading sistemini bozmadan üzerine ekle

---

## ✅ TAMAMLANMA KRİTERLERİ

- [ ] PdfRenderQueue çalışıyor
- [ ] Visible sayfa anında render ediliyor
- [ ] Adjacent sayfalar (±1) hemen arkasından render ediliyor
- [ ] Scroll yönüne göre prefetch çalışıyor
- [ ] Document açılışında bekleme yok
- [ ] Memory limiti aşılmıyor (50MB)
- [ ] Page navigator'dan atlama hızlı
- [ ] 60 FPS scroll
- [ ] Mevcut testler geçiyor
- [ ] Commit ve push yapıldı

---

## 📊 BEKLENEN PERFORMANS İYİLEŞMELERİ

| Metrik | Önceki | Sonrası |
|--------|--------|---------|
| İlk sayfa görünümü | 2-3 sn | <500ms |
| Sayfa geçişi | 1-2 sn | <100ms |
| Scroll FPS | 30-45 | 60 |
| Loading dialog | Var | Yok |

---

*Bu döküman Senior Architect tarafından hazırlanmıştır. Sorularınız için Product Owner'a (İlyas) danışın.*
