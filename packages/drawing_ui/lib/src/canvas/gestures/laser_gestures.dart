part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Laser pointer handlers.
mixin _LaserGestures<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T>, _GestureState<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // LASER POINTER EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleLaserDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);
    final settings = ref.read(laserSettingsProvider);

    laserController.startStroke(
      canvasPoint,
      color: settings.color,
      thickness: settings.thickness,
      mode: settings.mode,
      lineStyle: settings.lineStyle,
    );
    isLaserDrawing = true;
    lastPoint = event.localPosition;
  }

  void handleLaserMove(PointerMoveEvent event) {
    // Distance filter to avoid excessive points
    final lastPointValue = lastPoint;
    if (lastPointValue != null) {
      final distance = (event.localPosition - lastPointValue).distance;
      if (distance < DrawingCanvasGestureHandlers.minPointDistance) return;
    }

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);
    laserController.addPoint(canvasPoint);
    lastPoint = event.localPosition;
  }

  void handleLaserUp(PointerUpEvent event) {
    final settings = ref.read(laserSettingsProvider);
    final fadeDuration = Duration(
      milliseconds: (settings.duration * 1000).round(),
    );
    laserController.endStroke(fadeDuration);
    isLaserDrawing = false;
    lastPoint = null;
  }
}
