import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/session/active_editor_leave_provider.dart';

/// Publishes [leave] through [activeEditorLeaveProvider] while mounted.
class ActiveEditorLeaveScope extends ConsumerStatefulWidget {
  const ActiveEditorLeaveScope({
    super.key,
    required this.leave,
    required this.child,
  });

  final EditorLeave leave;
  final Widget child;

  @override
  ConsumerState<ActiveEditorLeaveScope> createState() =>
      _ActiveEditorLeaveScopeState();
}

class _ActiveEditorLeaveScopeState
    extends ConsumerState<ActiveEditorLeaveScope> {
  late final ProviderContainer _container;

  Future<bool> _leave() => widget.leave();

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    // Providers must not change while the tree is building.
    Future.microtask(() {
      if (mounted) {
        _container.read(activeEditorLeaveProvider.notifier).state = _leave;
      }
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      final notifier = _container.read(activeEditorLeaveProvider.notifier);
      if (notifier.state == _leave) notifier.state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
