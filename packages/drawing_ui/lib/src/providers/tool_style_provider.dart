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
    // Pen tools (9 types)
    case ToolType.pencil:
    case ToolType.hardPencil:
    case ToolType.ballpointPen:
    case ToolType.gelPen:
    case ToolType.dashedPen:
    case ToolType.brushPen:
    case ToolType.marker:
      return _getPenStyle(ref, toolType);

    // Highlighter tools
    case ToolType.highlighter:
    case ToolType.neonHighlighter:
      return _getHighlighterStyle(ref, toolType);

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
StrokeStyle _getHighlighterStyle(Ref ref, ToolType toolType) {
  final settings = ref.watch(highlighterSettingsProvider);

  if (toolType == ToolType.neonHighlighter) {
    // Neon highlighter with glow effect
    return StrokeStyle(
      color: settings.color.toARGB32(),
      thickness: settings.thickness * 0.75, // Slightly thinner
      opacity: 0.8,
      nibShape: NibShape.rectangle,
      blendMode: DrawingBlendMode.normal,
      isEraser: false,
      glowRadius: 8.0,
      glowIntensity: 0.6,
    );
  }

  // Regular highlighter
  return StrokeStyle(
    color: settings.color.toARGB32(),
    thickness: settings.thickness,
    opacity: 0.4, // Semi-transparent
    nibShape: NibShape.rectangle,
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
/// Returns true for pen, highlighter, and eraser tools.
final isDrawingToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);

  return const [
    ToolType.pencil,
    ToolType.hardPencil,
    ToolType.ballpointPen,
    ToolType.gelPen,
    ToolType.dashedPen,
    ToolType.highlighter,
    ToolType.brushPen,
    ToolType.marker,
    ToolType.neonHighlighter,
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
