import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';

/// Source of PDFs delivered by the platform (cold and warm start).
abstract interface class IncomingPdfSource {
  /// Single-subscription stream. Emits PDFs that were waiting at start-up
  /// first, then every PDF that arrives while the app is running.
  Stream<IncomingPdf> watch();
}
