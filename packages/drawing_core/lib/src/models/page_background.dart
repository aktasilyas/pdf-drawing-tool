import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:drawing_core/src/models/json_value_equality.dart';
import 'package:drawing_core/src/models/template.dart';
import 'package:drawing_core/src/models/template_pattern.dart';

/// Sayfa arka plan türleri
enum BackgroundType {
  blank,
  grid,
  lined,
  dotted,
  pdf,

  /// Template-based background (uses TemplatePattern for rendering)
  template,

  /// Cover-based background (uses Cover model for rendering)
  cover,
}

/// Sayfa arka plan modeli
class PageBackground {
  final BackgroundType type;
  final int color; // ARGB
  final double? gridSpacing;
  final double? lineSpacing;
  final int? lineColor;

  /// Template pattern for template-based backgrounds
  final TemplatePattern? templatePattern;

  /// Template spacing in mm (for template-based backgrounds)
  final double? templateSpacingMm;

  /// Template line width (for template-based backgrounds)
  final double? templateLineWidth;

  /// Template-specific extra data (JSON-safe), e.g. margins, zones, ratios.
  final Map<String, dynamic>? templateExtraData;

  /// Cover ID for cover-based backgrounds
  final String? coverId;

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
    this.templatePattern,
    this.templateSpacingMm,
    this.templateLineWidth,
    this.templateExtraData,
    this.coverId,
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

  /// Template-based background carrying all template geometry and extraData.
  factory PageBackground.fromTemplate(
    Template t, {
    int? color,
    int? lineColor,
  }) {
    return PageBackground(
      type: BackgroundType.template,
      color: color ?? t.defaultBackgroundColor,
      lineColor: lineColor ?? t.defaultLineColor,
      templatePattern: t.pattern,
      templateSpacingMm: t.spacingMm,
      templateLineWidth: t.lineWidth,
      templateExtraData: _freeze(t.extraData),
    );
  }

  static Map<String, dynamic>? _freeze(Map? m) =>
      m == null ? null : Map<String, dynamic>.unmodifiable(m);

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
    TemplatePattern? templatePattern,
    double? templateSpacingMm,
    double? templateLineWidth,
    Map<String, dynamic>? templateExtraData,
    String? coverId,
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
      templatePattern: templatePattern ?? this.templatePattern,
      templateSpacingMm: templateSpacingMm ?? this.templateSpacingMm,
      templateLineWidth: templateLineWidth ?? this.templateLineWidth,
      templateExtraData: templateExtraData ?? this.templateExtraData,
      coverId: coverId ?? this.coverId,
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
      if (templatePattern != null) 'templatePattern': templatePattern!.name,
      if (templateSpacingMm != null) 'templateSpacingMm': templateSpacingMm,
      if (templateLineWidth != null) 'templateLineWidth': templateLineWidth,
      if (templateExtraData != null && templateExtraData!.isNotEmpty)
        'templateExtraData': templateExtraData,
      if (coverId != null) 'coverId': coverId,
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
        developer.log('Failed to decode pdfDataBase64: $e',
            name: 'PageBackground');
      }
    }

    // Parse template pattern
    TemplatePattern? templatePattern;
    if (json['templatePattern'] != null) {
      try {
        templatePattern = TemplatePattern.values.firstWhere(
          (p) => p.name == json['templatePattern'],
        );
      } catch (e) {
        developer.log('Unknown template pattern: ${json['templatePattern']}',
            name: 'PageBackground');
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
      templatePattern: templatePattern,
      templateSpacingMm: parseDouble(json['templateSpacingMm']),
      templateLineWidth: parseDouble(json['templateLineWidth']),
      templateExtraData: _freeze(json['templateExtraData'] as Map?),
      coverId: json['coverId'] as String?,
      pdfPageIndex: parseInt(json['pdfPageIndex']),
      pdfFilePath: json['pdfFilePath'] as String?,
      pdfData: pdfData, // Decoded from base64 or null for lazy loading
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageBackground &&
        other.type == type &&
        other.color == color &&
        other.gridSpacing == gridSpacing &&
        other.lineSpacing == lineSpacing &&
        other.lineColor == lineColor &&
        other.templatePattern == templatePattern &&
        other.templateSpacingMm == templateSpacingMm &&
        other.templateLineWidth == templateLineWidth &&
        jsonDeepEquals(other.templateExtraData, templateExtraData) &&
        other.coverId == coverId &&
        identical(other.pdfData, pdfData) &&
        other.pdfPageIndex == pdfPageIndex &&
        other.pdfFilePath == pdfFilePath;
  }

  @override
  int get hashCode => Object.hash(
        type,
        color,
        gridSpacing,
        lineSpacing,
        lineColor,
        templatePattern,
        templateSpacingMm,
        templateLineWidth,
        jsonDeepHash(templateExtraData),
        coverId,
        pdfData == null ? null : identityHashCode(pdfData),
        pdfPageIndex,
        pdfFilePath,
      );
}
