import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:drawing_ui/src/canvas/laser_controller.dart';
import 'package:drawing_ui/src/canvas/laser_painter.dart';

/// Overlay widget that renders laser strokes with frame-driven animation.
///
/// Uses a [Ticker] to drive fade-out animations. The ticker only runs
/// when there are visible strokes, consuming zero CPU when idle.
///
/// Wrapped in [IgnorePointer] so it doesn't intercept touch events,
/// and [RepaintBoundary] for layer isolation.
class LaserOverlayWidget extends StatefulWidget {
  const LaserOverlayWidget({
    super.key,
    required this.controller,
    required this.size,
  });

  final LaserController controller;
  final Size size;

  @override
  State<LaserOverlayWidget> createState() => _LaserOverlayWidgetState();
}

class _LaserOverlayWidgetState extends State<LaserOverlayWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  bool _isTickerActive = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(LaserOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _syncTicker();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.controller.needsAnimation && !_isTickerActive) {
      _ticker.start();
      _isTickerActive = true;
    } else if (!widget.controller.needsAnimation && _isTickerActive) {
      _ticker.stop();
      _isTickerActive = false;
    }
  }

  void _onTick(Duration elapsed) {
    widget.controller.tick();
    // Stop ticker when no more strokes to animate
    if (!widget.controller.needsAnimation && _isTickerActive) {
      _ticker.stop();
      _isTickerActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: widget.size,
          painter: LaserPainter(controller: widget.controller),
          isComplex: false,
          willChange: true,
        ),
      ),
    );
  }
}
