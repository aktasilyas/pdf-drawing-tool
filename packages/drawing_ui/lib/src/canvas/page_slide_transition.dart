import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

/// Wraps canvas content and provides slide transition between pages.
///
/// Captures a RepaintBoundary screenshot of the current page before
/// navigation, then animates the old screenshot out while the new
/// page slides in.
class PageSlideTransition extends StatefulWidget {
  const PageSlideTransition({super.key, required this.child});
  final Widget child;

  @override
  State<PageSlideTransition> createState() => PageSlideTransitionState();
}

class PageSlideTransitionState extends State<PageSlideTransition>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller;
  ui.Image? _snapshot;
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _snapshot?.dispose();
        _snapshot = null;
      });
    }
  }

  /// Captures screenshot of current canvas. Call BEFORE changing page.
  Future<void> captureSnapshot({required bool forward}) async {
    // If already transitioning, complete instantly
    if (_snapshot != null) {
      _controller.value = 1.0;
      _snapshot?.dispose();
      _snapshot = null;
    }

    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) return;

    try {
      final image = await boundary.toImage(pixelRatio: 1.0);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _snapshot = image;
        _isForward = forward;
      });
    } catch (_) {
      // Screenshot failed — fallback to instant page change
    }
  }

  /// Starts the slide animation. Call AFTER providers have updated.
  void startAnimation() {
    if (_snapshot == null) return;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final child = RepaintBoundary(
      key: _boundaryKey,
      child: widget.child,
    );

    if (_snapshot == null) return child;

    final dir = _isForward ? -1.0 : 1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                children: [
                  // Old page sliding out
                  Transform.translate(
                    offset: Offset(dir * t * w, 0),
                    child: RawImage(image: _snapshot, fit: BoxFit.none),
                  ),
                  // New page sliding in
                  Transform.translate(
                    offset: Offset(-dir * (1 - t) * w, 0),
                    child: child,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
