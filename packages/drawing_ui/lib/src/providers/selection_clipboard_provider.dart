import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// In-memory clipboard data for selection copy/cut operations.
class SelectionClipboardData {
  /// Copied strokes.
  final List<Stroke> strokes;

  /// Copied shapes.
  final List<Shape> shapes;

  /// Copied images.
  final List<ImageElement> images;

  /// Copied texts.
  final List<TextElement> texts;

  /// Original bounding box of the copied selection.
  final BoundingBox originalBounds;

  const SelectionClipboardData({
    required this.strokes,
    required this.shapes,
    this.images = const [],
    this.texts = const [],
    required this.originalBounds,
  });
}

/// Provider for in-memory selection clipboard.
final selectionClipboardProvider = StateProvider<SelectionClipboardData?>((ref) {
  return null;
});

/// State for the long-press paste context menu.
class PasteMenuState {
  /// Position in screen coordinates (for overlay positioning).
  final Offset screenPos;

  /// Position in canvas coordinates (for paste target).
  final Offset canvasPos;

  const PasteMenuState({required this.screenPos, required this.canvasPos});
}

/// Provider for the paste context menu triggered by long press.
final pasteMenuProvider = StateProvider<PasteMenuState?>((ref) => null);
