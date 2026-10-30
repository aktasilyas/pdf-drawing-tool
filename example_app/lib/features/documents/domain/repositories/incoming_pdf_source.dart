import 'package:example_app/features/documents/domain/entities/incoming_pdf.dart';

/// Source of PDFs delivered by the platform (cold and warm start).
abstract interface class IncomingPdfSource {
  /// Single-subscription stream. Emits events that were waiting at start-up
  /// first, then every event that arrives while the app is running: an
  /// [IncomingPdf] for each readable PDF, an [IncomingPdfFailure] for each one
  /// that could not be copied.
  Stream<IncomingPdfEvent> watch();
}
