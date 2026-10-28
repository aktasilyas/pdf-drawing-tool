import 'dart:typed_data';
import 'package:drawing_core/src/models/json_value_equality.dart';
import 'package:drawing_core/src/models/page_background_json.dart';
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

  /// Image file reference for image pages (container-relative, e.g.
  /// `elyanotes_images/<name>`). When set, the image bytes live in that file
  /// and are not serialized; [pdfData] is only an in-memory cache.
  final String? imageFilePath;

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
    this.imageFilePath,
  });

  /// Whether this is an image page: it has an [imageFilePath], or it is a
  /// legacy PDF-typed page that carries inline image bytes without a
  /// [pdfFilePath].
  bool get isImage =>
      imageFilePath != null ||
      (type == BackgroundType.pdf && pdfFilePath == null && pdfData != null);

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

  static Map<String, dynamic>? _freeze(Map? m) => freezeTemplateExtraData(m);

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
    String? imageFilePath,
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
      imageFilePath: imageFilePath ?? this.imageFilePath,
    );
  }

  /// JSON serialization (see `page_background_json.dart`).
  ///
  /// For PDFs with `pdfFilePath` and image pages with `imageFilePath`, the
  /// bytes are NOT serialized; only the file reference is.
  Map<String, dynamic> toJson() => pageBackgroundToJson(this);

  factory PageBackground.fromJson(Map<String, dynamic> json) =>
      pageBackgroundFromJson(json);

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
        other.pdfFilePath == pdfFilePath &&
        other.imageFilePath == imageFilePath;
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
        imageFilePath,
      );
}
