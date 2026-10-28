import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:drawing_core/src/models/page_background.dart';
import 'package:drawing_core/src/models/template_pattern.dart';

/// Unmodifiable copy of template extra data, or null.
Map<String, dynamic>? freezeTemplateExtraData(Map? m) =>
    m == null ? null : Map<String, dynamic>.unmodifiable(m);

/// Serializes [b].
///
/// Inline bytes (`pdfDataBase64`) are written only for legacy image pages
/// that have neither a `pdfFilePath` nor an `imageFilePath`.
Map<String, dynamic> pageBackgroundToJson(PageBackground b) {
  final inlineBytes =
      b.pdfFilePath == null && b.imageFilePath == null && b.pdfData != null;
  return {
    'type': b.type.name,
    'color': b.color,
    if (b.gridSpacing != null) 'gridSpacing': b.gridSpacing,
    if (b.lineSpacing != null) 'lineSpacing': b.lineSpacing,
    if (b.lineColor != null) 'lineColor': b.lineColor,
    if (b.templatePattern != null) 'templatePattern': b.templatePattern!.name,
    if (b.templateSpacingMm != null) 'templateSpacingMm': b.templateSpacingMm,
    if (b.templateLineWidth != null) 'templateLineWidth': b.templateLineWidth,
    if (b.templateExtraData != null && b.templateExtraData!.isNotEmpty)
      'templateExtraData': b.templateExtraData,
    if (b.coverId != null) 'coverId': b.coverId,
    if (b.pdfPageIndex != null) 'pdfPageIndex': b.pdfPageIndex,
    if (b.pdfFilePath != null) 'pdfFilePath': b.pdfFilePath,
    if (b.imageFilePath != null) 'imageFilePath': b.imageFilePath,
    if (inlineBytes) 'pdfDataBase64': base64Encode(b.pdfData!),
  };
}

/// Parses a background. Source precedence: `pdfFilePath`, then
/// `imageFilePath`, then legacy `pdfDataBase64`; bytes are only decoded in the
/// last case.
PageBackground pageBackgroundFromJson(Map<String, dynamic> json) {
  int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.parse(value);
    if (value is num) return value.toInt();
    return null;
  }

  double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is String) return double.parse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  final pdfFilePath = json['pdfFilePath'] as String?;
  final imageFilePath = json['imageFilePath'] as String?;

  Uint8List? pdfData;
  if (pdfFilePath == null &&
      imageFilePath == null &&
      json['pdfDataBase64'] != null) {
    try {
      pdfData = base64Decode(json['pdfDataBase64'] as String);
    } catch (e) {
      developer.log('Failed to decode pdfDataBase64: $e',
          name: 'PageBackground');
    }
  }

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
    templateExtraData:
        freezeTemplateExtraData(json['templateExtraData'] as Map?),
    coverId: json['coverId'] as String?,
    pdfPageIndex: parseInt(json['pdfPageIndex']),
    pdfFilePath: pdfFilePath,
    imageFilePath: imageFilePath,
    pdfData: pdfData,
  );
}
