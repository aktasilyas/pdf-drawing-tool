import 'package:flutter/widgets.dart';

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

/// An [OverlayEntry] that is registered with [DismissibleOverlays] while it
/// is shown, so system Back closes it. [close] is idempotent: Back, a tap on
/// the scrim and widget disposal may race.
class DismissibleOverlayEntry {
  DismissibleOverlayEntry._(this._entry);

  /// Inserts the overlay built by [builder] into [overlay] and registers it.
  /// [onClosed] runs once, after the entry is removed.
  factory DismissibleOverlayEntry.show(
    OverlayState overlay,
    WidgetBuilder builder, {
    VoidCallback? onClosed,
  }) {
    final self = DismissibleOverlayEntry._(OverlayEntry(builder: builder));
    self._onClosed = onClosed;
    overlay.insert(self._entry);
    self._unregister = DismissibleOverlays.instance.register(self.close);
    return self;
  }

  final OverlayEntry _entry;
  VoidCallback? _onClosed;
  late final VoidCallback _unregister;
  bool _closed = false;

  /// Whether the overlay has been closed.
  bool get isClosed => _closed;

  /// Removes the overlay and unregisters it. Safe to call repeatedly.
  void close() {
    if (_closed) return;
    _closed = true;
    _unregister();
    _entry.remove();
    _onClosed?.call();
  }
}
