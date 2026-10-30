import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:example_app/features/editor/presentation/providers/editor_session.dart';

/// Keeps unsaved ink from being lost when the user leaves the editor.
///
/// - App paused, hidden, inactive or detached: flushes any pending autosave
///   right away instead of waiting for the debounce timer. Once the app is
///   hidden, the text being typed is committed first (#489).
/// - System back: first closes the topmost open popover or phone drawer
///   ([DismissibleOverlays], #482); with none open it is routed through
///   [onLeave] (the same save-then-leave path as the in-app Home button)
///   instead of popping the route directly.
class EditorLeaveGuard extends ConsumerStatefulWidget {
  const EditorLeaveGuard({
    super.key,
    required this.onLeave,
    required this.child,
  });

  /// Saves and navigates away. Called at most once at a time.
  final Future<void> Function() onLeave;

  final Widget child;

  @override
  ConsumerState<EditorLeaveGuard> createState() => _EditorLeaveGuardState();
}

class _EditorLeaveGuardState extends ConsumerState<EditorLeaveGuard> {
  late final AppLifecycleListener _lifecycle;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChange);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    // Inactive alone (notification shade, system dialog) keeps the text box
    // open; once the app is hidden the typed text is committed (#489).
    if (state != AppLifecycleState.inactive) {
      commitTextBeingEdited(ref.read);
    }
    ref.read(autoSaveProvider.notifier).flush();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    try {
      await widget.onLeave();
    } finally {
      if (mounted) _leaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (DismissibleOverlays.instance.dismissTopmost()) return;
        _leave();
      },
      child: widget.child,
    );
  }
}
