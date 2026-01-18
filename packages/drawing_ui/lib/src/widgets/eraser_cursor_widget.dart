import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/canvas/eraser_cursor_painter.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';

/// Widget that displays eraser cursor overlay.
/// Positioned absolutely over the canvas.
class EraserCursorWidget extends ConsumerWidget {
  const EraserCursorWidget({
    super.key,
    required this.cursorPosition,
    required this.isVisible,
    this.lassoPoints = const [],
  });
  
  final Offset cursorPosition;
  final bool isVisible;
  final List<Offset> lassoPoints;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();
    
    final eraserSettings = ref.watch(eraserSettingsProvider);
    
    final mode = switch (eraserSettings.mode) {
      EraserMode.pixel => EraserCursorMode.pixel,
      EraserMode.stroke => EraserCursorMode.stroke,
      EraserMode.lasso => EraserCursorMode.lasso,
    };
    
    return IgnorePointer(
      child: CustomPaint(
        painter: EraserCursorPainter(
          position: cursorPosition,
          size: eraserSettings.size,
          mode: mode,
          lassoPoints: lassoPoints,
          isActive: lassoPoints.isNotEmpty,
        ),
        size: Size.infinite,
      ),
    );
  }
}
