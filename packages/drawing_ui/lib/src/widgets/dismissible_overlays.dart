import 'package:flutter/foundation.dart';

/// Transient editor UI (popovers, the phone page drawer) that system Back
/// must close before it leaves the notebook (#482).
///
/// Overlays register while open; the editor's leave guard asks
/// [dismissTopmost] first. A plain stack, not a provider: popovers are
/// controlled imperatively and register from outside the widget tree.
class DismissibleOverlays {
  DismissibleOverlays._();

  /// The registry shared by the whole app.
  static final DismissibleOverlays instance = DismissibleOverlays._();

  final List<_Entry> _stack = [];

  /// Whether anything is open.
  bool get isEmpty => _stack.isEmpty;

  /// Registers an open overlay whose [close] dismisses it. Returns the
  /// function that unregisters it; call it when the overlay goes away by any
  /// route. Calling it twice is harmless.
  VoidCallback register(VoidCallback close) {
    final entry = _Entry(close);
    _stack.add(entry);
    return () => _stack.remove(entry);
  }

  /// Closes the most recently opened overlay. Returns false when none is open.
  bool dismissTopmost() {
    if (_stack.isEmpty) return false;
    final entry = _stack.removeLast();
    entry.close();
    return true;
  }

  /// Removes every entry; for tests.
  @visibleForTesting
  void reset() => _stack.clear();
}

class _Entry {
  _Entry(this.close);
  final VoidCallback close;
}
