import 'dart:typed_data';

/// Sayfa arka plan türleri
enum BackgroundType {
  blank,
  grid,
  lined,
  dotted,
  pdf,
}

/// Sayfa arka plan modeli
class PageBackground {
  final BackgroundType type;
  final int color; // ARGB
  final double? gridSpacing;
  final double? lineSpacing;
  final int? lineColor;
  final Uint8List? pdfData;
  final int? pdfPageIndex;

  const PageBackground({
    required this.type,
    this.color = 0xFFFFFFFF, // White default
    this.gridSpacing,
    this.lineSpacing,
    this.lineColor,
    this.pdfData,
    this.pdfPageIndex,
  });

  /// Blank white background
  static const blank = PageBackground(type: BackgroundType.blank);

  /// Grid background (default 20px spacing)
  static const grid = PageBackground(
    type: BackgroundType.grid,
    gridSpacing: 20,
    lineColor: 0xFFE0E0E0,
  );

  /// Lined background (notebook style)
  static const lined = PageBackground(
    type: BackgroundType.lined,
    lineSpacing: 24,
    lineColor: 0xFFE0E0E0,
  );

  /// Dotted background
  static const dotted = PageBackground(
    type: BackgroundType.dotted,
    gridSpacing: 20,
    lineColor: 0xFFCCCCCC,
  );

  /// Create PDF background
  factory PageBackground.pdf({
    required Uint8List pdfData,
    required int pageIndex,
  }) {
    return PageBackground(
      type: BackgroundType.pdf,
      pdfData: pdfData,
      pdfPageIndex: pageIndex,
    );
  }

  /// Copy with
  PageBackground copyWith({
    BackgroundType? type,
    int? color,
    double? gridSpacing,
    double? lineSpacing,
    int? lineColor,
    Uint8List? pdfData,
    int? pdfPageIndex,
  }) {
    return PageBackground(
      type: type ?? this.type,
      color: color ?? this.color,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      lineColor: lineColor ?? this.lineColor,
      pdfData: pdfData ?? this.pdfData,
      pdfPageIndex: pdfPageIndex ?? this.pdfPageIndex,
    );
  }

  /// JSON serialization (PDF data excluded for size)
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'color': color,
    if (gridSpacing != null) 'gridSpacing': gridSpacing,
    if (lineSpacing != null) 'lineSpacing': lineSpacing,
    if (lineColor != null) 'lineColor': lineColor,
    if (pdfPageIndex != null) 'pdfPageIndex': pdfPageIndex,
    // pdfData is stored separately
  };

  factory PageBackground.fromJson(Map<String, dynamic> json) {
    return PageBackground(
      type: BackgroundType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BackgroundType.blank,
      ),
      color: json['color'] as int? ?? 0xFFFFFFFF,
      gridSpacing: (json['gridSpacing'] as num?)?.toDouble(),
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble(),
      lineColor: json['lineColor'] as int?,
      pdfPageIndex: json['pdfPageIndex'] as int?,
    );
  }
}
