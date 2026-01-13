/// Hit testing için abstract interface.
///
/// Generic bir hit testing sistemi sağlar. Her element tipi
/// (Stroke, Shape, Text vs.) için ayrı HitTester implementasyonu yapılır.
///
/// Performans kritik! Bounding box pre-filter kullanılmalı.
///
/// Hedef: <5ms per hit test
abstract class HitTester<T> {
  /// Verilen noktada element var mı?
  ///
  /// [element] - Test edilecek element
  /// [x], [y] - Test noktası koordinatları
  /// [tolerance] - Hit için kabul edilebilir maksimum mesafe (piksel)
  ///
  /// Returns: Element hit oldu mu?
  bool hitTest(T element, double x, double y, double tolerance);

  /// Verilen noktadaki tüm elementleri bul.
  ///
  /// [elements] - Aranacak element listesi
  /// [x], [y] - Test noktası koordinatları
  /// [tolerance] - Hit için kabul edilebilir maksimum mesafe
  ///
  /// Returns: Hit olan tüm elementler (çizim sırasına göre)
  List<T> findElementsAt(
    List<T> elements,
    double x,
    double y,
    double tolerance,
  );

  /// En üstteki (son çizilen) elementi bul.
  ///
  /// Eraser gibi araçlar için optimize edilmiş versiyon.
  /// İlk hit'te durur (early exit).
  ///
  /// [elements] - Aranacak element listesi (çizim sırasına göre)
  /// [x], [y] - Test noktası koordinatları
  /// [tolerance] - Hit için kabul edilebilir maksimum mesafe
  ///
  /// Returns: En üstteki hit olan element veya null
  T? findTopElementAt(
    List<T> elements,
    double x,
    double y,
    double tolerance,
  );
}
