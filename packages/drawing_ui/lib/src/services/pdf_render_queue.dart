import 'dart:collection';

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
      other is RenderRequest &&
          cacheKey == other.cacheKey &&
          isLowRes == other.isLowRes;

  @override
  int get hashCode => Object.hash(cacheKey, isLowRes);
}

/// PDF Render Queue - Priority based rendering
///
/// Bu sınıf PDF sayfa render işlemlerini öncelik sırasına göre yönetir.
/// Görünen sayfa en yüksek önceliğe sahipken, uzak sayfalar daha düşük
/// önceliğe sahiptir.
///
/// Özellikler:
/// - Priority-based queue (visible > adjacent > prefetch > background)
/// - Max 2 concurrent render (CPU'yu yormamak için)
/// - Stale request cancellation (hızlı scroll'da eski istekleri iptal)
/// - Scroll direction prediction (scroll yönüne göre prefetch)
class PdfRenderQueue {
  final _queue = SplayTreeSet<RenderRequest>();
  final _inProgress = <String>{};
  final _completed = <String>{};

  bool _isProcessing = false;
  final int _maxConcurrent = 2; // Aynı anda max 2 render

  /// Render işlemi için callback
  Future<void> Function(RenderRequest request)? onRender;

  /// Render tamamlandığında callback
  void Function(String cacheKey)? onCompleted;

  /// Queue'ya istek ekle
  void enqueue(RenderRequest request) {
    // Zaten tamamlandıysa skip (sessizce)
    if (_completed.contains(request.cacheKey)) {
      return;
    }

    // Zaten işlemde ise skip (sessizce)
    if (_inProgress.contains(request.cacheKey)) {
      return;
    }

    // Aynı sayfa farklı priority ile varsa, yüksek priority olanı tut
    final existing =
        _queue.where((r) => r.cacheKey == request.cacheKey).firstOrNull;
    if (existing != null) {
      if (request.priority.value < existing.priority.value) {
        _queue.remove(existing);
        _queue.add(request);
      }
      return;
    }

    _queue.add(request);
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
        _enqueueForPage(
            visibleIndex - offset, pdfFilePath, RenderPriority.prefetch);
      }
      if (visibleIndex + offset < totalPages) {
        _enqueueForPage(
            visibleIndex + offset, pdfFilePath, RenderPriority.prefetch);
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

  void _enqueueForPage(
      int pageIndex, String pdfFilePath, RenderPriority priority) {
    final cacheKey =
        '$pdfFilePath|${pageIndex + 1}'; // pageIndex 0-based, PDF 1-based
    enqueue(RenderRequest(
      cacheKey: cacheKey,
      pageIndex: pageIndex,
      priority: priority,
    ));
  }

  void _cancelStaleRequests(int visibleIndex) {
    // Visible'dan 5+ uzaktaki prefetch'leri iptal et (sessizce)
    final toRemove = <RenderRequest>[];
    for (final request in _queue) {
      final distance = (request.pageIndex - visibleIndex).abs();
      if (distance > 5 && request.priority == RenderPriority.prefetch) {
        toRemove.add(request);
      }
    }
    for (final request in toRemove) {
      _queue.remove(request);
    }
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
      } catch (e) {
        // Render failed, silently continue
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

  /// Cache'den çıkarıldığında completed'dan da kaldır
  void markAsEvicted(String cacheKey) {
    _completed.remove(cacheKey);
  }

  /// Tüm queue'yu temizle
  void clear() {
    _queue.clear();
    _inProgress.clear();
    // _completed temizleme - cache'deki veriler korunmalı
  }

  /// Tüm state'i temizle (PDF değiştiğinde)
  void reset() {
    _queue.clear();
    _inProgress.clear();
    _completed.clear();
  }

  /// İstatistikler
  int get queueLength => _queue.length;
  int get inProgressCount => _inProgress.length;
  int get completedCount => _completed.length;

  /// Bir sayfa zaten render edilmiş mi?
  bool isCompleted(String cacheKey) => _completed.contains(cacheKey);

  /// Bir sayfa şu an render ediliyor mu?
  bool isInProgress(String cacheKey) => _inProgress.contains(cacheKey);

  /// Bir sayfa queue'da mı?
  bool isQueued(String cacheKey) =>
      _queue.any((r) => r.cacheKey == cacheKey);
}
