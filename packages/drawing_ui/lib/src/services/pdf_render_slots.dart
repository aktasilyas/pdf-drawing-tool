import 'dart:async';

/// Concurrency gate for PDF page rasterisation.
///
/// Every render claims a key (e.g. `path|3` or `path|3@2.5x`) and a slot.
/// A claimed key is always released by the caller in a `finally`, so no
/// exit path can leave a key behind. When all slots are busy, callers wait
/// in a LIFO queue (newest request first, which favours the page the user
/// is looking at while scrolling) instead of timing out.
class PdfRenderSlots {
  PdfRenderSlots({this.maxConcurrent = 2})
      : assert(maxConcurrent > 0, 'maxConcurrent must be positive');

  /// Maximum number of renders running at the same time.
  final int maxConcurrent;

  final Set<String> _keys = <String>{};
  final Map<String, Completer<void>> _idle = <String, Completer<void>>{};
  final List<Completer<void>> _waiters = <Completer<void>>[];
  int _active = 0;

  /// Number of renders holding a slot.
  int get activeCount => _active;

  /// Number of renders waiting for a slot.
  int get waitingCount => _waiters.length;

  /// Whether [key] is claimed (waiting for a slot or rendering).
  bool isBusy(String key) => _keys.contains(key);

  /// Claims [key] and waits until a slot is free.
  ///
  /// Returns `false` immediately (without claiming) when [key] is already
  /// claimed. After `true`, the caller owns a slot and must call [release]
  /// with the same key exactly once.
  Future<bool> acquire(String key) async {
    if (_keys.contains(key)) return false;
    _keys.add(key);
    _idle[key] = Completer<void>();
    if (_active < maxConcurrent) {
      _active++;
      return true;
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    // The slot is handed over by [release]; no re-check needed.
    await waiter.future;
    return true;
  }

  /// Releases [key] and its slot. Unknown keys are ignored.
  void release(String key) {
    if (!_keys.remove(key)) return;
    _idle.remove(key)?.complete();
    if (_waiters.isNotEmpty) {
      // Hand the slot straight to the newest waiter.
      _waiters.removeLast().complete();
    } else {
      _active--;
    }
  }

  /// Completes when [key] is released (immediately if it is not claimed).
  Future<void> whenIdle(String key) =>
      _idle[key]?.future ?? Future<void>.value();
}
