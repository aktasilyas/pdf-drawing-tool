import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

// =============================================================================
// TOOL STYLE PROVIDER
// =============================================================================

/// Returns the active StrokeStyle based on current tool and settings.
///
/// This provider bridges the UI tool selection with the drawing_core
/// StrokeStyle model. When the user changes tool, color, or thickness,
/// this provider automatically updates to reflect those changes.
final activeStrokeStyleProvider = Provider<StrokeStyle>((ref) {
  final toolType = ref.watch(currentToolProvider);

  switch (toolType) {
    // Pen tools
    case ToolType.ballpointPen:
    case ToolType.fountainPen:
    case ToolType.pencil:
    case ToolType.brush:
      return _getPenStyle(ref, toolType);

    // Highlighter
    case ToolType.highlighter:
      return _getHighlighterStyle(ref);

    // Eraser tools
    case ToolType.pixelEraser:
    case ToolType.strokeEraser:
    case ToolType.lassoEraser:
      return _getEraserStyle(ref);

    // Non-drawing tools - return default
    case ToolType.shapes:
    case ToolType.text:
    case ToolType.sticker:
    case ToolType.image:
    case ToolType.selection:
    case ToolType.panZoom:
    case ToolType.laserPointer:
      return StrokeStyle.pen();
  }
});

/// Creates StrokeStyle from pen settings.
StrokeStyle _getPenStyle(Ref ref, ToolType toolType) {
  final settings = ref.watch(penSettingsProvider(toolType));

  return StrokeStyle(
    color: settings.color.toARGB32(),
    thickness: settings.thickness,
    opacity: 1.0,
    nibShape: _convertNibShape(settings.nibShape),
    blendMode: DrawingBlendMode.normal,
    isEraser: false,
  );
}

/// Creates StrokeStyle for highlighter.
StrokeStyle _getHighlighterStyle(Ref ref) {
  final settings = ref.watch(highlighterSettingsProvider);

  return StrokeStyle(
    color: settings.color.toARGB32(),
    thickness: settings.thickness,
    opacity: 0.5, // Highlighter is semi-transparent
    nibShape: NibShape.rectangle, // Chisel tip for highlighter
    blendMode: DrawingBlendMode.normal,
    isEraser: false,
  );
}

/// Creates StrokeStyle for eraser.
StrokeStyle _getEraserStyle(Ref ref) {
  final settings = ref.watch(eraserSettingsProvider);

  return StrokeStyle(
    color: 0xFFFFFFFF, // White color for eraser
    thickness: settings.size,
    opacity: 1.0,
    nibShape: NibShape.circle,
    blendMode: DrawingBlendMode.normal,
    isEraser: true,
  );
}

/// Converts UI NibShapeType to drawing_core NibShape.
NibShape _convertNibShape(NibShapeType nibType) {
  switch (nibType) {
    case NibShapeType.circle:
      return NibShape.circle;
    case NibShapeType.ellipse:
      return NibShape.ellipse;
    case NibShapeType.rectangle:
      return NibShape.rectangle;
  }
}

// =============================================================================
// DRAWING TOOL CHECK
// =============================================================================

/// Whether the current tool is a drawing tool.
///
/// Use this to enable/disable pointer event handling.
/// Returns true for pen, highlighter, brush, and eraser tools.
final isDrawingToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);

  return const [
    ToolType.ballpointPen,
    ToolType.fountainPen,
    ToolType.pencil,
    ToolType.brush,
    ToolType.highlighter,
    ToolType.pixelEraser,
    ToolType.strokeEraser,
    ToolType.lassoEraser,
  ].contains(toolType);
});

/// Whether the current tool is an eraser.
final isEraserToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);

  return const [
    ToolType.pixelEraser,
    ToolType.strokeEraser,
    ToolType.lassoEraser,
  ].contains(toolType);
});

/// Whether the current tool is a pen-type tool.
final isPenToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);

  return const [
    ToolType.ballpointPen,
    ToolType.fountainPen,
    ToolType.pencil,
    ToolType.brush,
    ToolType.highlighter,
  ].contains(toolType);
});

/// Whether the current tool is the selection tool.
final isSelectionToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);
  return toolType == ToolType.selection;
});
