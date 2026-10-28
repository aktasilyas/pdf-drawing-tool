import 'dart:async';

/// Serializes content writes per document so they land in call order.
///
/// Large encodes yield mid-way, so without this a stale autosave that started
/// first could finish last and overwrite a newer save. Writes for different
/// documents run independently.
class DocumentContentWriteQueue {
  /// Newest pending write per document id.
  final Map<String, Future<void>> _pending = {};

  /// Whether a write for [id] is still queued or running.
  bool isPending(String id) => _pending.containsKey(id);

  /// Runs [write] after every earlier write for [id] has settled.
  ///
  /// The returned future completes with [write]'s result; an earlier write's
  /// error is reported only to its own caller and does not block this one.
  Future<void> enqueue(String id, Future<void> Function() write) {
    final next = _runAfter(_pending[id], write);
    _pending[id] = next;
    unawaited(
      next.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
        if (identical(_pending[id], next)) _pending.remove(id);
      }),
    );
    return next;
  }

  static Future<void> _runAfter(
    Future<void>? previous,
    Future<void> Function() write,
  ) async {
    if (previous != null) {
      try {
        await previous;
      } catch (_) {
        // Already reported to the caller of that write.
      }
    }
    await write();
  }
}
