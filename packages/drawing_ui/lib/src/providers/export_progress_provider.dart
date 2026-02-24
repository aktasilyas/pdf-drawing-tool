import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status of an ongoing PDF export operation.
enum ExportProgressStatus { idle, exporting, completed, error }

/// Immutable state for the export progress indicator.
class ExportProgressState {
  final ExportProgressStatus status;
  final double progress;
  final int currentPage;
  final int totalPages;
  final DateTime? startTime;
  final String? errorMessage;
  final String? fileSize;

  const ExportProgressState({
    this.status = ExportProgressStatus.idle,
    this.progress = 0.0,
    this.currentPage = 0,
    this.totalPages = 0,
    this.startTime,
    this.errorMessage,
    this.fileSize,
  });

  ExportProgressState copyWith({
    ExportProgressStatus? status,
    double? progress,
    int? currentPage,
    int? totalPages,
    DateTime? startTime,
    String? errorMessage,
    String? fileSize,
  }) {
    return ExportProgressState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      startTime: startTime ?? this.startTime,
      errorMessage: errorMessage ?? this.errorMessage,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  /// Estimated remaining time based on elapsed time and progress.
  String get estimatedTimeRemaining {
    if (startTime == null || currentPage <= 0) return '';
    final elapsed = DateTime.now().difference(startTime!);
    final remaining = elapsed * ((totalPages - currentPage) / currentPage);
    final seconds = remaining.inSeconds;
    if (seconds <= 0) return '';
    if (seconds < 60) return '~$seconds sn';
    return '~${remaining.inMinutes} dk';
  }
}

/// Notifier that drives the floating export progress indicator.
class ExportProgressNotifier extends StateNotifier<ExportProgressState> {
  ExportProgressNotifier() : super(const ExportProgressState());

  Timer? _autoDismissTimer;

  void start(int totalPages) {
    _autoDismissTimer?.cancel();
    state = ExportProgressState(
      status: ExportProgressStatus.exporting,
      totalPages: totalPages,
      startTime: DateTime.now(),
    );
  }

  void updateProgress(int current, int total) {
    if (state.status != ExportProgressStatus.exporting) return;
    state = state.copyWith(
      currentPage: current,
      totalPages: total,
      progress: total > 0 ? current / total : 0.0,
    );
  }

  void complete(String fileSize) {
    state = state.copyWith(
      status: ExportProgressStatus.completed,
      progress: 1.0,
      fileSize: fileSize,
    );
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 3), dismiss);
  }

  void setError(String message) {
    state = state.copyWith(
      status: ExportProgressStatus.error,
      errorMessage: message,
    );
  }

  void dismiss() {
    _autoDismissTimer?.cancel();
    state = const ExportProgressState();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }
}

/// Global provider for PDF export progress state.
final exportProgressProvider =
    StateNotifierProvider<ExportProgressNotifier, ExportProgressState>(
  (ref) => ExportProgressNotifier(),
);
