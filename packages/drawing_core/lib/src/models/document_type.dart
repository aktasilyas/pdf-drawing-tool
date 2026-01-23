/// Doküman tipleri - her biri farklı canvas davranışına sahip
enum DocumentType {
  /// Not defteri - sayfa bazlı, şablonlu, sınırlı canvas
  notebook,

  /// Beyaz tahta - sonsuz canvas, sayfa sınırı yok
  whiteboard,

  /// Hızlı not - tek sayfa, minimal UI
  quickNote,

  /// Resim - import edilmiş resim üzerine çizim
  image,

  /// PDF - import edilmiş PDF üzerine annotation
  pdf,

  /// Metin dokümanı - zengin metin editörü (ileride)
  textDocument,
}

extension DocumentTypeExtension on DocumentType {
  /// Canvas sonsuz mu? (sayfa sınırı yok)
  bool get isInfiniteCanvas {
    switch (this) {
      case DocumentType.whiteboard:
        return true;
      case DocumentType.notebook:
      case DocumentType.quickNote:
      case DocumentType.image:
      case DocumentType.pdf:
      case DocumentType.textDocument:
        return false;
    }
  }

  /// Çoklu sayfa destekliyor mu?
  bool get supportsMultiplePages {
    switch (this) {
      case DocumentType.notebook:
      case DocumentType.pdf:
        return true;
      case DocumentType.whiteboard:
      case DocumentType.quickNote:
      case DocumentType.image:
      case DocumentType.textDocument:
        return false;
    }
  }

  /// Şablon seçimi gösterilsin mi?
  bool get showsTemplateSelection {
    switch (this) {
      case DocumentType.notebook:
      case DocumentType.quickNote:
        return true;
      case DocumentType.whiteboard:
      case DocumentType.image:
      case DocumentType.pdf:
      case DocumentType.textDocument:
        return false;
    }
  }

  /// Varsayılan arka plan rengi
  int get defaultBackgroundColor {
    switch (this) {
      case DocumentType.whiteboard:
        return 0xFFFFFFFF; // Pure white
      case DocumentType.notebook:
      case DocumentType.quickNote:
        return 0xFFFFFDE7; // Cream
      case DocumentType.image:
      case DocumentType.pdf:
        return 0xFF424242; // Dark gray (PDF viewer style)
      case DocumentType.textDocument:
        return 0xFFFFFFFF;
    }
  }

  /// Türkçe başlık
  String get displayName {
    switch (this) {
      case DocumentType.notebook:
        return 'Not Defteri';
      case DocumentType.whiteboard:
        return 'Beyaz Tahta';
      case DocumentType.quickNote:
        return 'Hızlı Not';
      case DocumentType.image:
        return 'Resim';
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.textDocument:
        return 'Metin Dokümanı';
    }
  }

  /// İkon adı (Material Icons)
  String get iconName {
    switch (this) {
      case DocumentType.notebook:
        return 'description';
      case DocumentType.whiteboard:
        return 'grid_on';
      case DocumentType.quickNote:
        return 'edit_note';
      case DocumentType.image:
        return 'image';
      case DocumentType.pdf:
        return 'picture_as_pdf';
      case DocumentType.textDocument:
        return 'article';
    }
  }
}
