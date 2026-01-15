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
///
/// For pen tools, uses PenType.toStrokeStyle() for proper configuration.
final activeStrokeStyleProvider = Provider<StrokeStyle>((ref) {
  final toolType = ref.watch(currentToolProvider);

  // Pen tools - use PenType for configuration
  final penType = toolType.penType;
  if (penType != null) {
    final settings = ref.watch(penSettingsProvider(toolType));
    return penType.toStrokeStyle(
      color: settings.color.toARGB32(),
      thickness: settings.thickness,
    );
  }

  // Highlighter (special case - uses separate settings provider)
  if (toolType == ToolType.highlighter) {
    final settings = ref.watch(highlighterSettingsProvider);
    return StrokeStyle(
      color: settings.color.toARGB32(),
      thickness: settings.thickness,
      opacity: 0.4,
      nibShape: NibShape.rectangle,
      blendMode: DrawingBlendMode.normal,
      isEraser: false,
    );
  }

  // Eraser tools
  if (toolType == ToolType.pixelEraser ||
      toolType == ToolType.strokeEraser ||
      toolType == ToolType.lassoEraser) {
    final settings = ref.watch(eraserSettingsProvider);
    return StrokeStyle(
      color: 0xFFFFFFFF,
      thickness: settings.size,
      opacity: 1.0,
      nibShape: NibShape.circle,
      blendMode: DrawingBlendMode.normal,
      isEraser: true,
    );
  }

  // Non-drawing tools - return default
  return StrokeStyle.pen();
});

/// Converts UI NibShapeType to drawing_core NibShape.
/// 
/// Note: This is kept for compatibility but may not be needed
/// since PenType.toStrokeStyle() handles this internally.
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
/// Returns true for pen, highlighter, and eraser tools.
final isDrawingToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);

  // Pen tools (uses isPenTool getter from ToolType)
  if (toolType.isPenTool) return true;

  // Highlighter
  if (toolType == ToolType.highlighter) return true;

  // Eraser tools
  return const [
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

  // Use the new isPenTool getter from ToolType
  return toolType.isPenTool;
});

/// Whether the current tool is the selection tool.
final isSelectionToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);
  return toolType == ToolType.selection;
});
