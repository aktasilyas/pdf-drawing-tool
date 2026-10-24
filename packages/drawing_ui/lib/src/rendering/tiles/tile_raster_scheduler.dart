import 'package:flutter/scheduler.dart';

import 'package:drawing_ui/src/rendering/tiles/page_tile_cache.dart';

/// Rasterizes the pending tiles of a [PageTileCache] over several frames.
///
/// Each frame rasterizes tiles nearest-first until [frameBudget] is spent
/// (at least one, so progress is guaranteed), then asks for another frame
/// while tiles remain. Clock and frame scheduling are injectable for tests.
class TileRasterScheduler {
  TileRasterScheduler({
    required this.cache,
    this.frameBudget = const Duration(milliseconds: 6),
    Duration Function()? now,
    void Function(FrameCallback callback)? scheduleFrame,
  })  : _now = now ?? _stopwatchClock(),
        _scheduleFrame = scheduleFrame ?? _bindingSchedule {
    cache.addListener(_onCacheChanged);
    _onCacheChanged();
  }

  final PageTileCache cache;

  /// Maximum time spent rasterizing in one frame.
  final Duration frameBudget;

  final Duration Function() _now;
  final void Function(FrameCallback callback) _scheduleFrame;

  bool _scheduled = false;
  bool _running = false;
  bool _disposed = false;

  static Duration Function() _stopwatchClock() {
    final sw = Stopwatch()..start();
    return () => sw.elapsed;
  }

  static void _bindingSchedule(FrameCallback callback) {
    SchedulerBinding.instance.scheduleFrameCallback(callback);
  }

  void _onCacheChanged() {
    if (_running || _scheduled || _disposed || !cache.hasPending) return;
    _scheduled = true;
    _scheduleFrame(_onFrame);
  }

  void _onFrame(Duration timeStamp) {
    _scheduled = false;
    if (_disposed) return;
    _running = true;
    try {
      final start = _now();
      do {
        if (!cache.rasterizeNextPending()) break;
      } while (cache.hasPending && _now() - start < frameBudget);
    } finally {
      _running = false;
    }
    _onCacheChanged();
  }

  void dispose() {
    _disposed = true;
    cache.removeListener(_onCacheChanged);
  }
}
