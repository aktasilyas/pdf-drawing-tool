import 'package:drawing_core/drawing_core.dart' as core;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';
import 'package:drawing_ui/src/models/tool_type.dart';

// =============================================================================
// SHAPE TOOL PROVIDERS
// =============================================================================

/// Whether the current tool is the shapes tool.
final isShapeToolProvider = Provider<bool>((ref) {
  final toolType = ref.watch(currentToolProvider);
  return toolType == ToolType.shapes;
});

/// Aktif layer'daki shapes.
final activeLayerShapesProvider = Provider<List<core.Shape>>((ref) {
  final document = ref.watch(documentProvider);
  if (document.layers.isEmpty) return const [];
  return document.layers[document.activeLayerIndex].shapes;
});

/// Maps UI ShapeType to core ShapeType.
/// UI ve core aynı 10 şekli destekliyor - birebir eşleşme.
core.ShapeType mapToCore(ShapeType uiType) {
  switch (uiType) {
    case ShapeType.line:
      return core.ShapeType.line;
    case ShapeType.arrow:
      return core.ShapeType.arrow;
    case ShapeType.rectangle:
      return core.ShapeType.rectangle;
    case ShapeType.ellipse:
      return core.ShapeType.ellipse;
    case ShapeType.triangle:
      return core.ShapeType.triangle;
    case ShapeType.diamond:
      return core.ShapeType.diamond;
    case ShapeType.star:
      return core.ShapeType.star;
    case ShapeType.pentagon:
      return core.ShapeType.pentagon;
    case ShapeType.hexagon:
      return core.ShapeType.hexagon;
    case ShapeType.plus:
      return core.ShapeType.plus;
  }
}

/// Returns the core ShapeType based on UI selection.
final activeCoreShapeTypeProvider = Provider<core.ShapeType>((ref) {
  final settings = ref.watch(shapesSettingsProvider);
  return mapToCore(settings.selectedShape);
});

/// Whether the current shape should be filled.
final shapeFilledProvider = Provider<bool>((ref) {
  final settings = ref.watch(shapesSettingsProvider);
  return settings.fillEnabled;
});

/// Returns the fill color for shapes (ARGB32).
final shapeFillColorProvider = Provider<int?>((ref) {
  final settings = ref.watch(shapesSettingsProvider);
  if (!settings.fillEnabled) return null;
  return settings.fillColor.toARGB32();
});

/// Returns the StrokeStyle for shape drawing.
final shapeStrokeStyleProvider = Provider<core.StrokeStyle>((ref) {
  final settings = ref.watch(shapesSettingsProvider);

  return core.StrokeStyle(
    color: settings.strokeColor.toARGB32(),
    thickness: settings.strokeThickness,
    opacity: 1.0,
    nibShape: core.NibShape.circle,
    blendMode: core.DrawingBlendMode.normal,
    isEraser: false,
  );
});
