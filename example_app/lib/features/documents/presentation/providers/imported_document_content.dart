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
