import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';

/// State of a PDF export.
enum PDFExportState {
  /// Idle, ready to start export.
  idle,

  /// Preparing pages for export.
  preparing,

  /// Exporting pages to PDF.
  exporting,

  /// Export completed successfully.
  completed,

  /// Export failed with error.
  error,
}

/// PDF Import state model.
class PDFImportStateModel {
  final PDFImportState state;
  final double progress;
  final PdfImportFailure? failure;

  const PDFImportStateModel({
    required this.state,
    required this.progress,
    this.failure,
  });

  bool get isLoading =>
      state == PDFImportState.loadingPDF ||
      state == PDFImportState.renderingPages ||
      state == PDFImportState.convertingPages;

  bool get hasError => state == PDFImportState.error;

  int get progressPercentage => (progress * 100).round();

  PDFImportStateModel copyWith({
    PDFImportState? state,
    double? progress,
    PdfImportFailure? failure,
  }) {
    return PDFImportStateModel(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      failure: failure ?? this.failure,
    );
  }
}

/// PDF Export state model.
class PDFExportStateModel {
  final PDFExportState state;
  final double progress;
  final ExportFailure? failure;

  const PDFExportStateModel({
    required this.state,
    required this.progress,
    this.failure,
  });

  bool get isExporting =>
      state == PDFExportState.preparing || state == PDFExportState.exporting;

  bool get hasError => state == PDFExportState.error;

  int get progressPercentage => (progress * 100).round();

  PDFExportStateModel copyWith({
    PDFExportState? state,
    double? progress,
    ExportFailure? failure,
  }) {
    return PDFExportStateModel(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      failure: failure ?? this.failure,
    );
  }
}

/// Notifier for PDF import state.
class PDFImportStateNotifier extends StateNotifier<PDFImportStateModel> {
  PDFImportStateNotifier()
      : super(const PDFImportStateModel(
          state: PDFImportState.idle,
          progress: 0.0,
        ));

  void updateState(PDFImportState newState) {
    state = state.copyWith(state: newState);
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void setError(PdfImportFailure failure) {
    state = state.copyWith(
      state: PDFImportState.error,
      failure: failure,
    );
  }

  void reset() {
    state = const PDFImportStateModel(
      state: PDFImportState.idle,
      progress: 0.0,
    );
  }
}

/// Notifier for PDF export state.
class PDFExportStateNotifier extends StateNotifier<PDFExportStateModel> {
  PDFExportStateNotifier()
      : super(const PDFExportStateModel(
          state: PDFExportState.idle,
          progress: 0.0,
        ));

  void updateState(PDFExportState newState) {
    state = state.copyWith(state: newState);
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void setError(ExportFailure failure) {
    state = state.copyWith(
      state: PDFExportState.error,
      failure: failure,
    );
  }

  void reset() {
    state = const PDFExportStateModel(
      state: PDFExportState.idle,
      progress: 0.0,
    );
  }
}

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
