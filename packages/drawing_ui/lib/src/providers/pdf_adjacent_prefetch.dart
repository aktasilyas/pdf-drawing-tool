import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/pdf_page_cache.dart';

/// Renders the PDF pages around the visible one (±1, ±2), [delay] after a
/// page change so the visible page gets the render slots first.
///
/// It lives in the provider container and uses the container's [Ref], never
/// a widget's, so a canvas disposed before the delay ends cannot be touched.
/// A newer page change cancels the pending prefetch, so paging quickly only
/// prefetches around the page the user stops on.
class PdfAdjacentPrefetcher {
  PdfAdjacentPrefetcher(this._ref, this._render);

  /// Wait after a page change before prefetching its neighbours.
  static const Duration delay = Duration(milliseconds: 500);

  /// Page offsets prefetched around the visible page, nearest first.
  static const List<int> offsets = [1, -1, 2, -2];

  final Ref _ref;
  final void Function(String cacheKey) _render;
  Timer? _timer;

  /// Whether a prefetch is waiting for its [delay].
  bool get isPending => _timer != null;

  /// Prefetches around 1-based [page] of [pdfFilePath] after [delay],
  /// replacing any prefetch still waiting.
  void schedule({
    required String pdfFilePath,
    required int page,
    required int totalPages,
  }) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      _prefetch(pdfFilePath, page, totalPages);
    });
  }

  /// Drops a prefetch that is still waiting.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _prefetch(String pdfFilePath, int page, int totalPages) {
    final cache = _ref.read(pdfPageCacheProvider);
    final slots = _ref.read(pdfRenderSlotsProvider);
    for (final offset in offsets) {
      final target = page + offset;
      if (target < 1 || target > totalPages) continue;
      final key = '$pdfFilePath|$target';
      if (!cache.containsKey(key) && !slots.isBusy(key)) _render(key);
    }
  }
}

/// Builds the [PdfAdjacentPrefetcher]; [render] starts the render of one
/// page cache key (`'<filePath>|<pageNumber>'`).
PdfAdjacentPrefetcher createPdfAdjacentPrefetcher(
  Ref ref,
  void Function(String cacheKey) render,
) {
  final prefetcher = PdfAdjacentPrefetcher(ref, render);
  ref.onDispose(prefetcher.cancel);
  return prefetcher;
}
