import 'dart:async';

import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status of an ongoing PDF export operation.
enum ExportProgressStatus { idle, exporting, completed, error, cancelled }

/// Immutable state for the export progress indicator.
class ExportProgressState {
  final ExportProgressStatus status;
  final double progress;
  final int currentPage;
  final int totalPages;
  final DateTime? startTime;
  final ExportFailure? failure;
  final String? fileSize;

  /// Pages of a completed export that went out without their PDF background
  /// because it could not be loaded.
  final int pagesMissingBackground;

  const ExportProgressState({
    this.status = ExportProgressStatus.idle,
    this.progress = 0.0,
    this.currentPage = 0,
    this.totalPages = 0,
    this.startTime,
    this.failure,
    this.fileSize,
    this.pagesMissingBackground = 0,
  });

  ExportProgressState copyWith({
    ExportProgressStatus? status,
    double? progress,
    int? currentPage,
    int? totalPages,
    DateTime? startTime,
    ExportFailure? failure,
    String? fileSize,
    int? pagesMissingBackground,
  }) {
    return ExportProgressState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      startTime: startTime ?? this.startTime,
      failure: failure ?? this.failure,
      fileSize: fileSize ?? this.fileSize,
      pagesMissingBackground:
          pagesMissingBackground ?? this.pagesMissingBackground,
    );
  }

  /// Estimated remaining time based on elapsed time and progress, or null
  /// when it cannot be estimated (or is under a second).
  Duration? get remaining {
    if (startTime == null || currentPage <= 0) return null;
    final elapsed = DateTime.now().difference(startTime!);
    final left = elapsed * ((totalPages - currentPage) / currentPage);
    if (left.inSeconds <= 0) return null;
    return left;
  }
}

/// Notifier that drives the floating export progress indicator.
class ExportProgressNotifier extends StateNotifier<ExportProgressState> {
  ExportProgressNotifier() : super(const ExportProgressState());

  Timer? _autoDismissTimer;
  bool _cancelRequested = false;

  bool get isCancelRequested => _cancelRequested;

  void requestCancel() {
    _cancelRequested = true;
  }

  void setCancelled() {
    state = state.copyWith(status: ExportProgressStatus.cancelled);
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(
      const Duration(milliseconds: 1200),
      dismiss,
    );
  }

  void start(int totalPages) {
    _autoDismissTimer?.cancel();
    _cancelRequested = false;
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

  /// Marks the export as saved. [pagesMissingBackground] pages went out
  /// without their PDF background; the overlay then stays up longer so the
  /// warning can be read.
  void complete(String fileSize, {int pagesMissingBackground = 0}) {
    state = state.copyWith(
      status: ExportProgressStatus.completed,
      progress: 1.0,
      fileSize: fileSize,
      pagesMissingBackground: pagesMissingBackground,
    );
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(
      Duration(seconds: pagesMissingBackground > 0 ? 6 : 3),
      dismiss,
    );
  }

  void setError(ExportFailure failure) {
    state = state.copyWith(
      status: ExportProgressStatus.error,
      failure: failure,
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

/// Whether exports should include a watermark (free-tier).
/// Override from the host app to control based on subscription tier.
final exportWatermarkProvider = Provider<bool>((ref) => false);
