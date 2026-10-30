import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/dismissible_overlays.dart';
import 'package:drawing_ui/src/widgets/popover_layout.dart';

/// Controller for showing/hiding popover panels
/// (docs/specs/52-editor-chrome.md, section 4 "Popover panel").
///
/// Lighter alternative to [AnchoredPanelController]. Positioning (below,
/// flipped above, or to the right of the anchor) is [PopoverLayout].
///
/// The panel is short-lived chrome: any pointer-down outside it closes it and
/// is swallowed, so a pen-down on the page never draws a stroke. Escape closes
/// it too. [hide] plays a 100ms exit before the overlay entry is removed.
class PopoverController {
  OverlayEntry? _overlayEntry;
  GlobalKey<_PopoverOverlayState>? _overlayKey;
  VoidCallback? _unregisterBack;

  /// Entries playing their exit animation, removed once it ends.
  final Set<OverlayEntry> _exiting = {};

  /// Whether the popover is currently showing (an exiting panel is not).
  bool get isShowing => _overlayEntry != null;

  /// Show popover anchored to the widget identified by [anchorKey].
  ///
  /// A popover that is already showing is replaced at once, without its exit.
  void show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required Widget child,
    VoidCallback? onDismiss,
    double maxWidth = 280,
  }) {
    _removeCurrent();
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context);
    final overlayKey = GlobalKey<_PopoverOverlayState>();
    _overlayKey = overlayKey;
    _overlayEntry = OverlayEntry(
      builder: (_) => _PopoverOverlay(
        key: overlayKey,
        anchorPosition: box.localToGlobal(Offset.zero),
        anchorSize: box.size,
        screenSize: MediaQuery.of(context).size,
        maxWidth: maxWidth,
        onDismiss: () {
          hide();
          onDismiss?.call();
        },
        child: child,
      ),
    );
    overlay.insert(_overlayEntry!);
    _unregisterBack = DismissibleOverlays.instance.register(hide);
  }

  /// Hide the popover, playing its exit animation first.
  void hide() {
    final entry = _overlayEntry;
    final state = _overlayKey?.currentState;
    _unregisterBack?.call();
    _unregisterBack = null;
    _overlayEntry = null;
    _overlayKey = null;
    if (entry == null) return;
    if (state == null) {
      entry.remove();
      return;
    }
    _exiting.add(entry);
    state.close().whenComplete(() {
      if (_exiting.remove(entry)) entry.remove();
    });
  }

  /// Dispose the controller, removing any panel immediately.
  void dispose() {
    _removeCurrent();
    for (final entry in _exiting) {
      entry.remove();
    }
    _exiting.clear();
  }

  void _removeCurrent() {
    _unregisterBack?.call();
    _unregisterBack = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayKey = null;
  }
}

class _PopoverOverlay extends StatefulWidget {
  const _PopoverOverlay({
    super.key,
    required this.anchorPosition,
    required this.anchorSize,
    required this.screenSize,
    required this.maxWidth,
    required this.onDismiss,
    required this.child,
  });
  final Offset anchorPosition;
  final Size anchorSize;
  final Size screenSize;
  final double maxWidth;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_PopoverOverlay> createState() => _PopoverOverlayState();
}

class _PopoverOverlayState extends State<_PopoverOverlay>
    with SingleTickerProviderStateMixin {
  static const double _borderWidth = 1;

  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  final FocusNode _focusNode = FocusNode(debugLabel: 'PopoverPanel');
  FocusNode? _previousFocus;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: ChromeDurations.fast,
      reverseDuration: ChromeDurations.instant,
    );
    final curve = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(curve);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _anim.forward();
    _previousFocus = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_closing) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Plays the exit animation; completes when it ends or is cancelled.
  Future<void> close() async {
    if (_closing) return;
    // No setState: hide() may run inside a provider listener. The barrier
    // stops hit testing on the next animation tick (see build).
    _closing = true;
    final previous = _previousFocus;
    if (_focusNode.hasFocus && previous != null && previous.context != null) {
      previous.requestFocus();
    }
    try {
      await _anim.reverse().orCancel;
    } on TickerCanceled {
      // Disposed mid-exit; the controller removes the entry anyway.
    }
  }

  void _dismiss() {
    if (_closing) return;
    widget.onDismiss();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final layout = PopoverLayout(
      anchor: widget.anchorPosition & widget.anchorSize,
      screenSize: widget.screenSize,
      maxWidth: widget.maxWidth,
    );
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) =>
            IgnorePointer(ignoring: _closing, child: child),
        child: Stack(children: [
          // Swallows every outside pointer so a pen-down never draws.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _dismiss(),
            ),
          ),
          Positioned(
            left: layout.left,
            top: layout.top,
            bottom: layout.bottom,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: layout.scaleAlignment,
                child: _panelBox(context, maxHeight: layout.maxHeight),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _panelBox(BuildContext context, {required double maxHeight}) {
    final palette = ChromePalette.of(context);
    const radius = BorderRadius.all(Radius.circular(ChromeRadius.xl));
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: radius,
        border: Border.all(color: palette.border, width: _borderWidth),
        boxShadow: DrawingShadows.panel(Theme.of(context).brightness),
      ),
      child: ClipRRect(
        // Concentric with the outer edge, inside the 1dp border.
        borderRadius: const BorderRadius.all(
          Radius.circular(ChromeRadius.xl - _borderWidth),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(child: widget.child),
        ),
      ),
    );
  }
}
