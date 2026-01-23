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
    this.surroundingAreaColor = 0xFFE5E5E5, // Light gray (default)
    this.pageBorderColor = 0x1A000000, // Black 10%
    this.pageBorderWidth = 1.0,
    this.minZoom = 0.25,
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
    minZoom: 0.1,
    maxZoom: 10.0,
    unlimitedPan: true,
  );

  /// Not defteri modu - sayfa bazlı
  static const notebook = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFFE5E5E5, // Light gray (like GoodNotes)
    pageBorderColor: 0x1A000000,
    pageBorderWidth: 1.0,
  );

  /// PDF görüntüleme modu
  static const pdfViewer = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFF424242, // Darker gray
    pageBorderColor: 0x00000000, // No border
    pageBorderWidth: 0.0,
  );

  /// Hızlı not modu - basit, tek sayfa
  static const quickNote = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFFE5E5E5, // Light gray (same as notebook)
    minZoom: 0.5,
    maxZoom: 3.0,
  );

  /// Resim üzerine çizim modu
  static const imageAnnotation = CanvasMode(
    isInfinite: false,
    allowDrawingOutsidePage: false,
    showPageShadow: true,
    surroundingAreaColor: 0xFF212121, // Very dark
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
