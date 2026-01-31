import 'package:drawing_core/src/models/document_type.dart';

/// Canvas davranış konfigürasyonu
class CanvasMode {
  /// Sonsuz canvas mi? (sayfa sınırı yok)
  final bool isInfinite;

  /// Sayfa dışına çizim yapılabilir mi?
  final bool allowDrawingOutsidePage;

  /// Sayfa etrafında gölge göster
  final bool showPageShadow;

  /// Sayfa etrafındaki alan rengi (çizilemez alan)
  final int surroundingAreaColor;

  /// Sayfa border rengi
  final int pageBorderColor;

  /// Sayfa border kalınlığı
  final double pageBorderWidth;

  /// Zoom limitleri
  final double minZoom;
  final double maxZoom;

  /// Pan sınırsız mı?
  final bool unlimitedPan;

  const CanvasMode({
    required this.isInfinite,
    this.allowDrawingOutsidePage = false,
    this.showPageShadow = true,
    this.surroundingAreaColor = 0xFFF5F5F0, // Warm off-white (kirli beyaz)
    this.pageBorderColor = 0x1A000000, // Black 10%
    this.pageBorderWidth = 1.0,
    this.minZoom = 0.01, // Allow extreme zoom out for large images/PDFs (was 0.25)
    this.maxZoom = 5.0,
    this.unlimitedPan = false,
  });

  /// Beyaz tahta modu - sonsuz canvas
  static const whiteboard = CanvasMode(
    isInfinite: true,
    allowDrawingOutsidePage: true, // Her yer çizilebilir
    showPageShadow: false,
    surroundingAreaColor: 0xFFFFFFFF, // Pure white (like GoodNotes)
    pageBorderColor: 0x00000000,
    pageBorderWidth: 0.0,
    minZoom: 0.05, // %5'e kadar zoom out (extreme wide view)
    maxZoom: 10.0,
    unlimitedPan: true,
  );

  /// Not defteri modu - sayfa bazlı
  static const notebook = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFFF5F5F0, // Warm off-white (kirli beyaz)
    pageBorderColor: 0x1A000000,
    pageBorderWidth: 1.0,
  );

  /// PDF görüntüleme modu
  static const pdfViewer = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFFF5F5F0, // Warm off-white (kirli beyaz)
    pageBorderColor: 0x00000000, // No border
    pageBorderWidth: 0.0,
  );

  /// Hızlı not modu - basit, tek sayfa
  static const quickNote = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFFF5F5F0, // Warm off-white (kirli beyaz)
    minZoom: 0.01, // Allow extreme zoom out (was 0.5)
    maxZoom: 3.0,
  );

  /// Resim üzerine çizim modu
  static const imageAnnotation = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFFF5F5F0, // Warm off-white (kirli beyaz)
    pageBorderColor: 0x00000000,
    pageBorderWidth: 0.0,
  );

  /// DocumentType'a göre CanvasMode al
  static CanvasMode fromDocumentType(DocumentType type) {
    switch (type) {
      case DocumentType.whiteboard:
        return whiteboard;
      case DocumentType.notebook:
        return notebook;
      case DocumentType.quickNote:
        return quickNote;
      case DocumentType.image:
        return imageAnnotation;
      case DocumentType.pdf:
        return pdfViewer;
      case DocumentType.textDocument:
        return notebook; // Varsayılan
    }
  }
}
