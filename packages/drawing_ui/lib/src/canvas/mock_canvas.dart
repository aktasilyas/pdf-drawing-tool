import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

import '../theme/drawing_theme.dart';
import '../providers/drawing_providers.dart';

/// A mock canvas widget for Phase 1 UI development.
///
/// This displays a placeholder canvas area. No real drawing logic is implemented.
/// Actual drawing will be added in Phase 2.
class MockCanvas extends ConsumerWidget {
  const MockCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = DrawingTheme.of(context);
    final currentTool = ref.watch(currentToolProvider);

    return Container(
      color: theme.canvasBackground,
      child: Stack(
        children: [
          // Grid pattern background
          const _GridPattern(),

          // Center placeholder message
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getToolIcon(currentTool),
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Canvas Area',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current tool: ${currentTool.displayName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '(Drawing will be implemented in Phase 2)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // MOCK: Cursor indicator that follows pointer
          _MockCursorIndicator(toolType: currentTool),
        ],
      ),
    );
  }

  IconData _getToolIcon(ToolType tool) {
    switch (tool) {
      case ToolType.ballpointPen:
        return Icons.edit;
      case ToolType.fountainPen:
        return Icons.create;
      case ToolType.pencil:
        return Icons.edit_outlined;
      case ToolType.brush:
        return Icons.brush;
      case ToolType.highlighter:
        return Icons.highlight;
      case ToolType.pixelEraser:
        return Icons.auto_fix_normal;
      case ToolType.strokeEraser:
        return Icons.cleaning_services;
      case ToolType.lassoEraser:
        return Icons.gesture;
      case ToolType.shapes:
        return Icons.crop_square;
      case ToolType.text:
        return Icons.text_fields;
      case ToolType.sticker:
        return Icons.emoji_emotions;
      case ToolType.image:
        return Icons.image;
      case ToolType.selection:
        return Icons.select_all;
      case ToolType.panZoom:
        return Icons.pan_tool;
      case ToolType.laserPointer:
        return Icons.highlight_alt;
    }
  }
}

/// Grid pattern background for canvas.
class _GridPattern extends StatelessWidget {
  const _GridPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    const gridSize = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Mock cursor indicator that shows tool preview.
class _MockCursorIndicator extends ConsumerStatefulWidget {
  const _MockCursorIndicator({required this.toolType});

  final ToolType toolType;

  @override
  ConsumerState<_MockCursorIndicator> createState() =>
      _MockCursorIndicatorState();
}

class _MockCursorIndicatorState extends ConsumerState<_MockCursorIndicator> {
  Offset? _cursorPosition;
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        setState(() {
          _cursorPosition = event.localPosition;
        });
      },
      onPointerDown: (event) {
        setState(() {
          _cursorPosition = event.localPosition;
          _isDrawing = true;
        });
      },
      onPointerUp: (event) {
        setState(() {
          _isDrawing = false;
        });
      },
      onPointerHover: (event) {
        setState(() {
          _cursorPosition = event.localPosition;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Transparent hit area
          const Positioned.fill(child: ColoredBox(color: Colors.transparent)),

          // Cursor indicator
          if (_cursorPosition != null)
            Positioned(
              left: _cursorPosition!.dx - 15,
              top: _cursorPosition!.dy - 15,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isDrawing
                          ? Colors.blue.withAlpha(180)
                          : Colors.grey.withAlpha(100),
                      width: 2,
                    ),
                    color: _isDrawing
                        ? Colors.blue.withAlpha(30)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
