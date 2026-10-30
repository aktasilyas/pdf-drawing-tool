import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

// =============================================================================
// TOOL STYLE PROVIDER
// =============================================================================

/// Returns the [StrokeStyle] a given tool would draw with.
///
/// Unlike [activeStrokeStyleProvider] this does not depend on the selected
/// tool, so the pen picker can preview every preset with its own settings.
/// Pen tools (and the highlighter) are built from `PenType.toStrokeStyle` so
/// the preset tuning (taper, blend mode) comes from drawing_core.
final strokeStyleForToolProvider =
    Provider.family<StrokeStyle, ToolType>((ref, toolType) {
  // Neon Highlighter (special case - uses highlighter settings + glow)
  if (toolType == ToolType.neonHighlighter) {
    final settings = ref.watch(highlighterSettingsProvider);
    return StrokeStyle(
      color: settings.color.toARGB32(),
      thickness: settings.thickness,
      opacity: 0.9,
      nibShape: NibShape.rectangle,
      blendMode: DrawingBlendMode.normal,
      isEraser: false,
      glowRadius: 4.0, // Daha az bulanık
      glowIntensity: settings.glowIntensity,
    );
  }

  // Highlighter: separate settings provider, preset config from PenType.
  if (toolType == ToolType.highlighter) {
    final settings = ref.watch(highlighterSettingsProvider);
    return PenType.highlighter.toStrokeStyle(
      color: settings.color.toARGB32(),
      thickness: settings.thickness,
    );
  }

  // Pen tools - use PenType for configuration
  final penType = toolType.penType;
  if (penType != null) {
    final settings = ref.watch(penSettingsProvider(toolType));
    return penType.toStrokeStyle(
      color: settings.color.toARGB32(),
      thickness: settings.thickness,
      pressureSensitive: settings.pressureSensitive,
      pressureSensitivity: settings.pressureSensitivity,
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

/// Returns the active StrokeStyle based on current tool and settings.
///
/// This provider bridges the UI tool selection with the drawing_core
/// StrokeStyle model. It is [strokeStyleForToolProvider] of the current tool.
final activeStrokeStyleProvider = Provider<StrokeStyle>((ref) {
  return ref.watch(strokeStyleForToolProvider(ref.watch(currentToolProvider)));
});

/// Converts UI NibShapeType to drawing_core NibShape.
///
/// Note: This is kept for compatibility but may not be needed
/// since PenType.toStrokeStyle() handles this internally.
// ignore: unused_element
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
  // Note: neonHighlighter.isPenTool is true but we handle it separately
  if (toolType.isPenTool && toolType != ToolType.neonHighlighter) return true;

  // Highlighter tools
  if (toolType == ToolType.highlighter ||
      toolType == ToolType.neonHighlighter) {
    return true;
  }

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

/// Whether the current tool is the selection tool.
final isSelectionToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);
  return toolType == ToolType.selection;
});
