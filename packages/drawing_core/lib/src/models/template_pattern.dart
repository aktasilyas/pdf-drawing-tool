/// Template pattern türleri.
/// 
/// Her pattern, sayfada çizilecek arka plan desenini belirler.
enum TemplatePattern {
  /// Boş sayfa - hiçbir desen yok
  blank,
  
  /// İnce çizgili (6mm spacing)
  thinLines,
  
  /// Orta çizgili (8mm spacing)
  mediumLines,
  
  /// Kalın çizgili (10mm spacing)
  thickLines,
  
  /// Küçük kareli (5mm spacing)
  smallGrid,
  
  /// Orta kareli (7mm spacing)
  mediumGrid,
  
  /// Büyük kareli (10mm spacing)
  largeGrid,
  
  /// Küçük noktalı (5mm spacing)
  smallDots,
  
  /// Orta noktalı (7mm spacing)
  mediumDots,
  
  /// Büyük noktalı (10mm spacing)
  largeDots,
  
  /// İzometrik grid (30° açılı)
  isometric,
  
  /// Altıgen grid
  hexagonal,
  
  /// Cornell notes (margin + summary)
  cornell,
  
  /// Müzik nota kağıdı (5 çizgi staff)
  music,
  
  /// El yazısı (baseline + midline)
  handwriting,
  
  /// Kaligrafi (açılı çizgiler)
  calligraphy,
}

/// TemplatePattern extension methods
extension TemplatePatternExtension on TemplatePattern {
  /// Pattern için varsayılan spacing (mm cinsinden)
  double get defaultSpacingMm {
    switch (this) {
      case TemplatePattern.blank:
        return 0;
      case TemplatePattern.thinLines:
        return 6;
      case TemplatePattern.mediumLines:
        return 8;
      case TemplatePattern.thickLines:
        return 10;
      case TemplatePattern.smallGrid:
      case TemplatePattern.smallDots:
        return 5;
      case TemplatePattern.mediumGrid:
      case TemplatePattern.mediumDots:
        return 7;
      case TemplatePattern.largeGrid:
      case TemplatePattern.largeDots:
        return 10;
      case TemplatePattern.isometric:
        return 10;
      case TemplatePattern.hexagonal:
        return 12;
      case TemplatePattern.cornell:
        return 8;
      case TemplatePattern.music:
        return 8;
      case TemplatePattern.handwriting:
        return 10;
      case TemplatePattern.calligraphy:
        return 12;
    }
  }
  
  /// Pattern için varsayılan çizgi kalınlığı (px)
  double get defaultLineWidth {
    switch (this) {
      case TemplatePattern.blank:
        return 0;
      case TemplatePattern.thinLines:
      case TemplatePattern.smallGrid:
      case TemplatePattern.smallDots:
        return 0.3;
      case TemplatePattern.mediumLines:
      case TemplatePattern.mediumGrid:
      case TemplatePattern.mediumDots:
        return 0.5;
      case TemplatePattern.thickLines:
      case TemplatePattern.largeGrid:
      case TemplatePattern.largeDots:
        return 0.7;
      default:
        return 0.5;
    }
  }
  
  /// Pattern çizgi içeriyor mu?
  bool get hasLines {
    return this == TemplatePattern.thinLines ||
           this == TemplatePattern.mediumLines ||
           this == TemplatePattern.thickLines ||
           this == TemplatePattern.cornell ||
           this == TemplatePattern.music ||
           this == TemplatePattern.handwriting ||
           this == TemplatePattern.calligraphy;
  }
  
  /// Pattern grid içeriyor mu?
  bool get hasGrid {
    return this == TemplatePattern.smallGrid ||
           this == TemplatePattern.mediumGrid ||
           this == TemplatePattern.largeGrid ||
           this == TemplatePattern.isometric ||
           this == TemplatePattern.hexagonal;
  }
  
  /// Pattern nokta içeriyor mu?
  bool get hasDots {
    return this == TemplatePattern.smallDots ||
           this == TemplatePattern.mediumDots ||
           this == TemplatePattern.largeDots;
  }
}
