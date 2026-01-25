import 'dart:convert';
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
  
  /// Rendered PDF image data (cache - lazy loaded)
  final Uint8List? pdfData;
  
  /// PDF page number (1-based)
  final int? pdfPageIndex;
  
  /// PDF file path for lazy loading (stored on device)
  final String? pdfFilePath;

  const PageBackground({
    required this.type,
    this.color = 0xFFFFFFFF, // White default
    this.gridSpacing,
    this.lineSpacing,
    this.lineColor,
    this.pdfData,
    this.pdfPageIndex,
    this.pdfFilePath,
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
  
  /// Create PDF background for lazy loading (with file path)
  factory PageBackground.pdfLazy({
    required int pageIndex,
    required String pdfFilePath,
  }) {
    return PageBackground(
      type: BackgroundType.pdf,
      pdfPageIndex: pageIndex,
      pdfFilePath: pdfFilePath,
      pdfData: null, // Will be loaded on-demand
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
    String? pdfFilePath,
  }) {
    return PageBackground(
      type: type ?? this.type,
      color: color ?? this.color,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      lineColor: lineColor ?? this.lineColor,
      pdfData: pdfData ?? this.pdfData,
      pdfPageIndex: pdfPageIndex ?? this.pdfPageIndex,
      pdfFilePath: pdfFilePath ?? this.pdfFilePath,
    );
  }

  /// JSON serialization
  /// Note: For PDFs with pdfFilePath, pdfData is NOT serialized (lazy loading)
  /// For images (no pdfFilePath), pdfData IS serialized (base64)
  Map<String, dynamic> toJson() {
    // Determine if we should serialize pdfData:
    // - If pdfFilePath exists: NO (lazy loading for PDFs)
    // - If pdfFilePath is null but pdfData exists: YES (images stored in memory)
    final shouldSerializePdfData = pdfFilePath == null && pdfData != null;
    
    return {
      'type': type.name,
      'color': color,
      if (gridSpacing != null) 'gridSpacing': gridSpacing,
      if (lineSpacing != null) 'lineSpacing': lineSpacing,
      if (lineColor != null) 'lineColor': lineColor,
      if (pdfPageIndex != null) 'pdfPageIndex': pdfPageIndex,
      if (pdfFilePath != null) 'pdfFilePath': pdfFilePath,
      if (shouldSerializePdfData) 'pdfDataBase64': base64Encode(pdfData!),
    };
  }

  factory PageBackground.fromJson(Map<String, dynamic> json) {
    // Helper to parse int safely
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.parse(value);
      if (value is num) return value.toInt();
      return null;
    }
    
    // Helper to parse double safely
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is String) return double.parse(value);
      if (value is num) return value.toDouble();
      return null;
    }
    
    // Decode pdfData from base64 if present (for images)
    Uint8List? pdfData;
    if (json['pdfDataBase64'] != null) {
      try {
        pdfData = base64Decode(json['pdfDataBase64'] as String);
      } catch (e) {
        print('❌ Failed to decode pdfDataBase64: $e');
      }
    }
    
    return PageBackground(
      type: BackgroundType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BackgroundType.blank,
      ),
      color: parseInt(json['color']) ?? 0xFFFFFFFF,
      gridSpacing: parseDouble(json['gridSpacing']),
      lineSpacing: parseDouble(json['lineSpacing']),
      lineColor: parseInt(json['lineColor']),
      pdfPageIndex: parseInt(json['pdfPageIndex']),
      pdfFilePath: json['pdfFilePath'] as String?,
      pdfData: pdfData, // Decoded from base64 or null for lazy loading
    );
  }
}
