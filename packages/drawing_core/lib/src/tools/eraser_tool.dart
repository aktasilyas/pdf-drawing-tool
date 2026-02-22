import 'package:drawing_core/src/internal.dart';

/// Eraser mode - silgi çalışma modu
enum EraserMode {
  /// Tüm çizgiyi sil (varsayılan)
  stroke,

  /// Nokta bazlı sil
  pixel,

  /// Seçim yaparak sil
  lasso,
}

/// Silgi aracı.
///
/// İki modda çalışır:
/// - [EraserMode.stroke]: Dokunulan çizginin tamamını siler
/// - [EraserMode.pixel]: Sadece dokunulan kısmı siler (gelecek sürüm)
///
/// Session tracking ile aynı gesture'da tekrar silmeyi engeller.
class EraserTool extends DrawingTool {
  /// Silgi modu
  final EraserMode mode;

  /// Silgi boyutu (piksel)
  final double eraserSize;

  /// Hit tester instance
  final StrokeHitTester _hitTester;

  /// Bir silme hareketi boyunca silinen stroke ID'leri
  final Set<String> _erasedStrokeIds = {};

  /// Yeni bir [EraserTool] oluşturur.
  ///
  /// [mode] - Silgi modu (varsayılan: stroke)
  /// [eraserSize] - Silgi boyutu piksel cinsinden (varsayılan: 20.0)
  EraserTool({
    this.mode = EraserMode.stroke,
    this.eraserSize = 20.0,
  })  : _hitTester = const StrokeHitTester(),
        super(StrokeStyle.eraser(thickness: eraserSize));

  /// Silme toleransı (eraser boyutunun yarısı)
  double get tolerance => eraserSize / 2;

  /// Verilen noktada silinecek stroke'ları bul.
  ///
  /// [strokes] - Aranacak stroke listesi
  /// [x], [y] - Silgi pozisyonu
  /// [toleranceOverride] - Canvas-space tolerance (null ise varsayılan kullanılır)
  ///
  /// Returns: Silinecek stroke'ların listesi
  List<Stroke> findStrokesToErase(
    List<Stroke> strokes,
    double x,
    double y, {
    double? toleranceOverride,
  }) {
    final t = toleranceOverride ?? tolerance;
    switch (mode) {
      case EraserMode.stroke:
        final stroke = _hitTester.findTopElementAt(strokes, x, y, t);
        return stroke != null ? [stroke] : [];

      case EraserMode.pixel:
        final stroke = _hitTester.findTopElementAt(strokes, x, y, t);
        return stroke != null ? [stroke] : [];

      case EraserMode.lasso:
        return [];
    }
  }

  /// Bir silme hareketi başlat.
  ///
  /// Önceki session'dan kalan ID'leri temizler.
  void startErasing() {
    _erasedStrokeIds.clear();
  }

  /// Stroke'u silinmiş olarak işaretle.
  ///
  /// Aynı gesture'da tekrar silmeyi engeller.
  void markAsErased(String strokeId) {
    _erasedStrokeIds.add(strokeId);
  }

  /// Bu harekette zaten silindi mi?
  ///
  /// Double-erase prevention için kullanılır.
  bool isAlreadyErased(String strokeId) {
    return _erasedStrokeIds.contains(strokeId);
  }

  /// Silme hareketini bitir ve silinen ID'leri döndür.
  ///
  /// Session'ı temizler ve silinen stroke ID'lerini döndürür.
  /// Bu ID'ler EraseStrokesCommand'a verilir.
  Set<String> endErasing() {
    final result = Set<String>.from(_erasedStrokeIds);
    _erasedStrokeIds.clear();
    return result;
  }

  /// Current erased stroke IDs in this session (read-only view).
  Set<String> get erasedIds => Set.unmodifiable(_erasedStrokeIds);

  /// Şu ana kadar silinen stroke sayısı
  int get erasedCount => _erasedStrokeIds.length;

  /// Aktif silme oturumunda en az bir stroke silindi mi?
  bool get hasErasedStrokes => _erasedStrokeIds.isNotEmpty;

  @override
  Stroke createStroke(List<DrawingPoint> points, StrokeStyle style) {
    // Eraser gerçek stroke oluşturmaz, boş stroke döndür
    return Stroke.create(style: style);
  }
}
