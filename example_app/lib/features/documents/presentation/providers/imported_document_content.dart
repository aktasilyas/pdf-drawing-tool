import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';

/// Builds the V2 document content map for a document created from
/// pre-rendered pages (PDF import).
Map<String, dynamic> buildImportedDocumentContent({
  required DocumentInfo document,
  required List<Map<String, dynamic>> pages,
  required DocumentType documentType,
  DateTime? now,
}) {
  // Round-trip through JSON so int/double/String types are consistent.
  final normalizedPages = jsonDecode(jsonEncode(pages)) as List;
  final updatedAt = now ?? DateTime.now();
  return {
    'version': 2,
    'id': document.id,
    'title': document.title,
    'pages': normalizedPages,
    'currentPageIndex': 0,
    'settings': {
      'defaultPageSize': {
        'width': 595.0,
        'height': 842.0,
        'preset': 'a4Portrait',
      },
      'defaultBackground': {
        'type': 'blank',
        'color': 4294967295, // 0xFFFFFFFF (white)
      },
    },
    'documentType': documentType.name,
    'createdAt': document.createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Paper metadata of an imported document, taken from its first page.
typedef ImportedPaper = ({bool isPortrait, double widthMm, double heightMm});

const double _mmPerPoint = 25.4 / 72;

/// Orientation and size (points → mm) of the first imported page; A4 portrait
/// when [pages] carry no usable size. Width/height are stored short/long, the
/// way `LibraryPageThumbnail.pageRect` reads them, with orientation in
/// `isPortrait`.
ImportedPaper importedPaperFromPages(List<Map<String, dynamic>> pages) {
  const fallback = (isPortrait: true, widthMm: 210.0, heightMm: 297.0);
  if (pages.isEmpty) return fallback;
  final size = pages.first['size'];
  if (size is! Map) return fallback;
  final w = size['width'];
  final h = size['height'];
  if (w is! num || h is! num || w <= 0 || h <= 0) return fallback;
  final shortMm = (w < h ? w : h) * _mmPerPoint;
  final longMm = (w < h ? h : w) * _mmPerPoint;
  return (isPortrait: w <= h, widthMm: shortMm, heightMm: longMm);
}
