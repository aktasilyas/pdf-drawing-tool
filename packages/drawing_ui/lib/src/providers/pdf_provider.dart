import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';

/// Provider for PDF import service.
final pdfImportServiceProvider = Provider<PDFImportService>((ref) {
  final service = PDFImportService(
    pdfPaths: ref.watch(pdfPathResolverProvider),
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
