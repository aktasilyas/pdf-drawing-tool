import 'package:flutter/widgets.dart';

/// Calls [onMemoryPressure] when the platform reports low memory (Android
/// `onTrimMemory`, iOS memory warnings).
///
/// The editor's cache owners create one in `initState` and [dispose] it with
/// themselves, so no callback fires after the editor is unmounted. The
/// callback only drops caches that are rebuilt on the next paint.
class EditorMemoryPressureObserver with WidgetsBindingObserver {
  /// Registers with [WidgetsBinding] right away.
  EditorMemoryPressureObserver(this.onMemoryPressure) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Frees rebuildable caches.
  final VoidCallback onMemoryPressure;

  bool _disposed = false;

  @override
  void didHaveMemoryPressure() {
    if (!_disposed) onMemoryPressure();
  }

  /// Unregisters; later memory pressure no longer calls [onMemoryPressure].
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }
}
