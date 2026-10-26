import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/canvas_dark_mode_provider.dart';

/// Mirrors the app theme brightness into [appBrightnessProvider] so the
/// canvas `followSystem` mode tracks the app theme, not the OS setting.
class CanvasBrightnessSync extends ConsumerStatefulWidget {
  const CanvasBrightnessSync({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CanvasBrightnessSync> createState() =>
      _CanvasBrightnessSyncState();
}

class _CanvasBrightnessSyncState extends ConsumerState<CanvasBrightnessSync> {
  Brightness? _lastWritten;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (brightness == _lastWritten) return;
    _lastWritten = brightness;
    // Providers cannot be written during build, so defer to post-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appBrightnessProvider.notifier).state = brightness;
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
