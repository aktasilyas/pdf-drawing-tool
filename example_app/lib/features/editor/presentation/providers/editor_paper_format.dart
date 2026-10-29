import 'package:dartz/dartz.dart' show Either;
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/errors/failures.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/editor/presentation/providers/editor_session.dart';

/// Hands the paper size of notebook [documentId] to PDF export, so an A4
/// notebook exports as an A4 PDF (#454).
///
/// The previous notebook's size is cleared first. The stored size already
/// has the orientation applied (landscape swaps width and height). A result
/// that arrives after another document was opened is dropped. Best effort:
/// on any error export falls back to page units, so this never throws.
Future<void> loadExportPaperFormat(
  ProviderReader read,
  String documentId,
) async {
  read(exportPageFormatProvider.notifier).state = null;
  final Either<Failure, DocumentInfo> result;
  try {
    result = await read(documentRepositoryProvider).getDocument(documentId);
  } catch (e) {
    logger.w('No paper size for PDF export: $e');
    return;
  }
  result.fold(
    (failure) => logger.w('No paper size for PDF export: ${failure.message}'),
    (info) {
      if (read(documentProvider).id != documentId) return;
      read(exportPageFormatProvider.notifier).state =
          PDFPageFormat.millimeters(info.paperWidthMm, info.paperHeightMm);
    },
  );
}
