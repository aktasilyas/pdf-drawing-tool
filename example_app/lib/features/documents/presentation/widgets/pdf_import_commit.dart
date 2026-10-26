import 'dart:io';

import 'package:drawing_core/drawing_core.dart' show Page, PdfPathResolver;

import 'package:example_app/core/utils/logger.dart';

/// Runs [create] (inserting the document for the imported [pages]) and keeps
/// app storage free of orphans: when [create] returns `null` or throws, the
/// PDF files the pages reference are deleted. A thrown error is rethrown.
Future<String?> commitPdfImport(
  List<Page> pages,
  Future<String?> Function() create,
  PdfPathResolver pdfPaths,
) async {
  try {
    final id = await create();
    if (id == null) await _deleteStoredPdfs(pages, pdfPaths);
    return id;
  } catch (_) {
    await _deleteStoredPdfs(pages, pdfPaths);
    rethrow;
  }
}

Future<void> _deleteStoredPdfs(
  List<Page> pages,
  PdfPathResolver pdfPaths,
) async {
  final stored = {
    for (final page in pages)
      if (page.background.pdfFilePath case final String path) path,
  };
  for (final path in stored) {
    try {
      final file = File(pdfPaths.resolve(path));
      if (await file.exists()) await file.delete();
    } catch (e) {
      logger.w('Could not delete orphan PDF $path: $e');
    }
  }
}
