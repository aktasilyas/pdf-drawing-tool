import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_export_service.dart';

/// PDF Import state model.
class PDFImportStateModel {
  final PDFImportState state;
  final double progress;
  final String? errorMessage;

  const PDFImportStateModel({
    required this.state,
    required this.progress,
    this.errorMessage,
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
    String? errorMessage,
  }) {
    return PDFImportStateModel(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// PDF Export state model.
class PDFExportStateModel {
  final PDFExportState state;
  final double progress;
  final String? errorMessage;

  const PDFExportStateModel({
    required this.state,
    required this.progress,
    this.errorMessage,
  });

  bool get isExporting =>
      state == PDFExportState.preparing || state == PDFExportState.exporting;

  bool get hasError => state == PDFExportState.error;

  int get progressPercentage => (progress * 100).round();

  PDFExportStateModel copyWith({
    PDFExportState? state,
    double? progress,
    String? errorMessage,
  }) {
    return PDFExportStateModel(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for PDF import state.
final pdfImportStateProvider =
    StateNotifierProvider<PDFImportStateNotifier, PDFImportStateModel>((ref) {
  return PDFImportStateNotifier();
});

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

  void setError(String message) {
    state = state.copyWith(
      state: PDFImportState.error,
      errorMessage: message,
    );
  }

  void reset() {
    state = const PDFImportStateModel(
      state: PDFImportState.idle,
      progress: 0.0,
    );
  }
}

/// Provider for PDF export state.
final pdfExportStateProvider =
    StateNotifierProvider<PDFExportStateNotifier, PDFExportStateModel>((ref) {
  return PDFExportStateNotifier();
});

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

  void setError(String message) {
    state = state.copyWith(
      state: PDFExportState.error,
      errorMessage: message,
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
  final service = PDFImportService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for PDF export service.
final pdfExportServiceProvider = Provider<PDFExportService>((ref) {
  final service = PDFExportService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Helper provider to check if import is in progress.
final isImportingProvider = Provider<bool>((ref) {
  final state = ref.watch(pdfImportStateProvider);
  return state.isLoading;
});

/// Helper provider to check if export is in progress.
final isExportingProvider = Provider<bool>((ref) {
  final state = ref.watch(pdfExportStateProvider);
  return state.isExporting;
});

/// Provider for import progress message.
final importProgressMessageProvider = Provider<String>((ref) {
  final state = ref.watch(pdfImportStateProvider);

  switch (state.state) {
    case PDFImportState.idle:
      return 'Ready to import';
    case PDFImportState.loadingPDF:
      return 'Loading PDF...';
    case PDFImportState.renderingPages:
      return 'Rendering pages...';
    case PDFImportState.convertingPages:
      return 'Converting pages (${state.progressPercentage}%)...';
    case PDFImportState.completed:
      return 'Import completed';
    case PDFImportState.error:
      return 'Error: ${state.errorMessage ?? "Unknown error"}';
  }
});

/// Provider for export progress message.
final exportProgressMessageProvider = Provider<String>((ref) {
  final state = ref.watch(pdfExportStateProvider);

  switch (state.state) {
    case PDFExportState.idle:
      return 'Ready to export';
    case PDFExportState.preparing:
      return 'Preparing export...';
    case PDFExportState.exporting:
      return 'Exporting (${state.progressPercentage}%)...';
    case PDFExportState.completed:
      return 'Export completed';
    case PDFExportState.error:
      return 'Error: ${state.errorMessage ?? "Unknown error"}';
  }
});
