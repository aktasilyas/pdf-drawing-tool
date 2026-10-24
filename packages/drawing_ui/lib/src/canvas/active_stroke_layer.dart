import 'package:flutter/widgets.dart';
import 'package:drawing_ui/src/canvas/drawing_controller.dart';
import 'package:drawing_ui/src/canvas/live_stroke_painter.dart';

/// Layer that shows the stroke being drawn.
///
/// The painter is created once and repaints through the controller, without
/// rebuilding any widget per pointer event.
class ActiveStrokeLayer extends StatefulWidget {
  const ActiveStrokeLayer({
    super.key,
    required this.controller,
    required this.size,
  });

  final DrawingController controller;
  final Size size;

  @override
  State<ActiveStrokeLayer> createState() => _ActiveStrokeLayerState();
}

class _ActiveStrokeLayerState extends State<ActiveStrokeLayer> {
  late LiveStrokePainter _painter = _create();

  LiveStrokePainter _create() => LiveStrokePainter(
        geometry: widget.controller.geometry,
        repaint: widget.controller,
      );

  @override
  void didUpdateWidget(ActiveStrokeLayer old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) _painter = _create();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: widget.size,
        painter: _painter,
        isComplex: false,
        willChange: true,
      );
}
