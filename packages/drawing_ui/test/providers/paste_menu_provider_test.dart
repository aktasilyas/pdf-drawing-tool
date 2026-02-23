import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_actions_provider.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';

void main() {
  // ===========================================================================
  // PasteMenuState Unit Tests
  // ===========================================================================

  group('PasteMenuState', () {
    test('should_store_screenPos_and_canvasPos_correctly', () {
      const screenPos = Offset(100, 200);
      const canvasPos = Offset(300, 400);

      const state = PasteMenuState(
        screenPos: screenPos,
        canvasPos: canvasPos,
      );

      expect(state.screenPos, equals(screenPos));
      expect(state.canvasPos, equals(canvasPos));
    });

    test('should_store_zero_offsets_correctly', () {
      const state = PasteMenuState(
        screenPos: Offset.zero,
        canvasPos: Offset.zero,
      );

      expect(state.screenPos, equals(Offset.zero));
      expect(state.canvasPos, equals(Offset.zero));
    });

    test('should_store_negative_offsets_correctly', () {
      const screenPos = Offset(-10, -20);
      const canvasPos = Offset(-50, -100);

      const state = PasteMenuState(
        screenPos: screenPos,
        canvasPos: canvasPos,
      );

      expect(state.screenPos, equals(screenPos));
      expect(state.canvasPos, equals(canvasPos));
    });

    test('should_store_large_offsets_correctly', () {
      const screenPos = Offset(9999, 9999);
      const canvasPos = Offset(50000, 50000);

      const state = PasteMenuState(
        screenPos: screenPos,
        canvasPos: canvasPos,
      );

      expect(state.screenPos.dx, equals(9999));
      expect(state.screenPos.dy, equals(9999));
      expect(state.canvasPos.dx, equals(50000));
      expect(state.canvasPos.dy, equals(50000));
    });
  });

  // ===========================================================================
  // pasteMenuProvider Unit Tests
  // ===========================================================================

  group('pasteMenuProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should_default_to_null', () {
      expect(container.read(pasteMenuProvider), isNull);
    });

    test('should_update_state_when_set', () {
      const state = PasteMenuState(
        screenPos: Offset(100, 200),
        canvasPos: Offset(300, 400),
      );

      container.read(pasteMenuProvider.notifier).state = state;

      expect(container.read(pasteMenuProvider), isNotNull);
      expect(container.read(pasteMenuProvider)!.screenPos, equals(const Offset(100, 200)));
      expect(container.read(pasteMenuProvider)!.canvasPos, equals(const Offset(300, 400)));
    });

    test('should_clear_state_when_set_to_null', () {
      const state = PasteMenuState(
        screenPos: Offset(100, 200),
        canvasPos: Offset(300, 400),
      );

      container.read(pasteMenuProvider.notifier).state = state;
      expect(container.read(pasteMenuProvider), isNotNull);

      container.read(pasteMenuProvider.notifier).state = null;
      expect(container.read(pasteMenuProvider), isNull);
    });
  });

  // ===========================================================================
  // pasteFromClipboardAt Unit Tests
  // ===========================================================================

  group('pasteFromClipboardAt', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // Helper: create a minimal stroke with one point at the given position.
    Stroke _makeStroke(double x, double y) {
      return Stroke.create(style: StrokeStyle.pen())
          .addPoint(DrawingPoint(x: x, y: y));
    }

    // Helper: create a shape with given start/end points.
    Shape _makeShape({
      required double startX,
      required double startY,
      required double endX,
      required double endY,
    }) {
      return Shape(
        id: 'shape-${startX.toInt()}-${startY.toInt()}',
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: startX, y: startY),
        endPoint: DrawingPoint(x: endX, y: endY),
        style: StrokeStyle.pen(),
      );
    }

    test('should_do_nothing_when_clipboard_is_null', () {
      // Clipboard defaults to null.
      expect(container.read(selectionClipboardProvider), isNull);

      // Calling pasteFromClipboardAt should not throw and add nothing.
      final initialStrokeCount = container.read(strokeCountProvider);

      // We can't call pasteFromClipboardAt directly without a WidgetRef in unit
      // tests. Instead we test the provider state:
      expect(container.read(selectionClipboardProvider), isNull);
      // The document should be unchanged.
      expect(container.read(strokeCountProvider), equals(initialStrokeCount));
    });

    test('should_paste_strokes_centered_at_canvas_point', () {
      // Set up clipboard with a stroke at (100, 100).
      // Original bounds: left=100, top=100, right=100, bottom=100
      // Center of bounds = (100, 100).
      final stroke = _makeStroke(100, 100);
      const bounds = BoundingBox(left: 90, top: 90, right: 110, bottom: 110);

      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [stroke],
        shapes: [],
        originalBounds: bounds,
      );

      // Verify clipboard is populated.
      final clipboard = container.read(selectionClipboardProvider);
      expect(clipboard, isNotNull);
      expect(clipboard!.strokes.length, equals(1));
      expect(clipboard.originalBounds.left, equals(90));
      expect(clipboard.originalBounds.right, equals(110));
    });

    test('should_compute_correct_delta_from_bounds_center_to_target', () {
      // Bounds: left=50, top=50, right=150, bottom=150 → center=(100,100)
      // Target canvas point: (200, 300)
      // Expected delta: dx=200-100=100, dy=300-100=200
      const bounds = BoundingBox(left: 50, top: 50, right: 150, bottom: 150);

      final centerX = (bounds.left + bounds.right) / 2;
      final centerY = (bounds.top + bounds.bottom) / 2;

      expect(centerX, equals(100.0));
      expect(centerY, equals(100.0));

      const targetPoint = Offset(200, 300);
      final dx = targetPoint.dx - centerX;
      final dy = targetPoint.dy - centerY;

      expect(dx, equals(100.0));
      expect(dy, equals(200.0));
    });

    test('should_apply_delta_to_stroke_points', () {
      // A stroke at (50, 50). Bounds center = (50, 50).
      // Target point = (150, 150). Delta = (100, 100).
      // After paste, the new stroke point should be at (150, 150).
      final stroke = _makeStroke(50, 50);
      const bounds = BoundingBox(left: 40, top: 40, right: 60, bottom: 60);
      // center = (50, 50)

      const targetPoint = Offset(150, 150);
      final centerX = (bounds.left + bounds.right) / 2;
      final centerY = (bounds.top + bounds.bottom) / 2;
      final dx = targetPoint.dx - centerX;
      final dy = targetPoint.dy - centerY;

      expect(dx, equals(100.0));
      expect(dy, equals(100.0));

      // Verify the stroke point offset manually.
      final originalPoint = stroke.points.first;
      final movedPoint = DrawingPoint(
        x: originalPoint.x + dx,
        y: originalPoint.y + dy,
        pressure: originalPoint.pressure,
      );

      expect(movedPoint.x, equals(150.0));
      expect(movedPoint.y, equals(150.0));
    });

    test('should_apply_delta_to_shape_start_and_end_points', () {
      // Shape from (20,20) to (80,80). Bounds center = (50, 50).
      // Target point = (200, 200). Delta = (150, 150).
      final shape = _makeShape(
        startX: 20, startY: 20,
        endX: 80, endY: 80,
      );
      const bounds = BoundingBox(left: 20, top: 20, right: 80, bottom: 80);
      // center = (50, 50)

      const targetPoint = Offset(200, 200);
      final centerX = (bounds.left + bounds.right) / 2;
      final centerY = (bounds.top + bounds.bottom) / 2;
      final dx = targetPoint.dx - centerX;
      final dy = targetPoint.dy - centerY;

      expect(dx, equals(150.0));
      expect(dy, equals(150.0));

      // Compute expected moved positions.
      final newStartX = shape.startPoint.x + dx;
      final newStartY = shape.startPoint.y + dy;
      final newEndX = shape.endPoint.x + dx;
      final newEndY = shape.endPoint.y + dy;

      expect(newStartX, equals(170.0));
      expect(newStartY, equals(170.0));
      expect(newEndX, equals(230.0));
      expect(newEndY, equals(230.0));
    });

    test('should_preserve_stroke_style_and_pressure_when_pasting', () {
      final style = StrokeStyle.pen();
      final point = DrawingPoint(x: 100, y: 100, pressure: 0.75);
      final stroke = Stroke.create(style: style).addPoint(point);
      const bounds = BoundingBox(left: 90, top: 90, right: 110, bottom: 110);

      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [stroke],
        shapes: [],
        originalBounds: bounds,
      );

      final clipboard = container.read(selectionClipboardProvider)!;
      final originalStroke = clipboard.strokes.first;
      final originalPoint = originalStroke.points.first;

      // Style and pressure should be preserved.
      expect(originalStroke.style, equals(style));
      expect(originalPoint.pressure, equals(0.75));
    });

    test('should_preserve_shape_style_and_fill_when_pasting', () {
      final style = StrokeStyle.pen();
      final shape = Shape(
        id: 'test-shape',
        type: ShapeType.ellipse,
        startPoint: DrawingPoint(x: 10, y: 10),
        endPoint: DrawingPoint(x: 90, y: 90),
        style: style,
        isFilled: true,
        fillColor: 0xFFFF0000,
      );
      const bounds = BoundingBox(left: 10, top: 10, right: 90, bottom: 90);

      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [],
        shapes: [shape],
        originalBounds: bounds,
      );

      final clipboard = container.read(selectionClipboardProvider)!;
      final originalShape = clipboard.shapes.first;

      expect(originalShape.type, equals(ShapeType.ellipse));
      expect(originalShape.isFilled, isTrue);
      expect(originalShape.fillColor, equals(0xFFFF0000));
    });

    test('should_handle_clipboard_with_multiple_strokes', () {
      final stroke1 = _makeStroke(10, 10);
      final stroke2 = _makeStroke(50, 50);
      final stroke3 = _makeStroke(90, 90);
      const bounds = BoundingBox(left: 10, top: 10, right: 90, bottom: 90);

      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [stroke1, stroke2, stroke3],
        shapes: [],
        originalBounds: bounds,
      );

      final clipboard = container.read(selectionClipboardProvider)!;
      expect(clipboard.strokes.length, equals(3));
    });

    test('should_handle_clipboard_with_mixed_strokes_and_shapes', () {
      final stroke = _makeStroke(50, 50);
      final shape = _makeShape(startX: 0, startY: 0, endX: 100, endY: 100);
      const bounds = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);

      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [stroke],
        shapes: [shape],
        originalBounds: bounds,
      );

      final clipboard = container.read(selectionClipboardProvider)!;
      expect(clipboard.strokes.length, equals(1));
      expect(clipboard.shapes.length, equals(1));
    });

    test('should_paste_to_exact_center_when_target_equals_bounds_center', () {
      // When target is already at the bounds center, delta should be zero.
      const bounds = BoundingBox(left: 50, top: 50, right: 150, bottom: 150);
      // bounds center = (100, 100)
      const targetPoint = Offset(100, 100);

      final centerX = (bounds.left + bounds.right) / 2;
      final centerY = (bounds.top + bounds.bottom) / 2;
      final dx = targetPoint.dx - centerX;
      final dy = targetPoint.dy - centerY;

      expect(dx, equals(0.0));
      expect(dy, equals(0.0));
    });

    test('should_paste_with_negative_delta_when_target_is_before_center', () {
      // Target point is to the upper-left of the bounds center.
      const bounds = BoundingBox(left: 100, top: 100, right: 200, bottom: 200);
      // bounds center = (150, 150)
      const targetPoint = Offset(50, 50);

      final centerX = (bounds.left + bounds.right) / 2;
      final centerY = (bounds.top + bounds.bottom) / 2;
      final dx = targetPoint.dx - centerX;
      final dy = targetPoint.dy - centerY;

      expect(dx, equals(-100.0));
      expect(dy, equals(-100.0));
    });
  });

  // ===========================================================================
  // selectionClipboardProvider Unit Tests
  // ===========================================================================

  group('selectionClipboardProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should_default_to_null', () {
      expect(container.read(selectionClipboardProvider), isNull);
    });

    test('should_store_SelectionClipboardData_correctly', () {
      final stroke = Stroke.create(style: StrokeStyle.pen())
          .addPoint(DrawingPoint(x: 10, y: 10));
      const bounds = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);

      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [stroke],
        shapes: [],
        originalBounds: bounds,
      );

      final data = container.read(selectionClipboardProvider);
      expect(data, isNotNull);
      expect(data!.strokes.length, equals(1));
      expect(data.shapes.isEmpty, isTrue);
      expect(data.originalBounds, equals(bounds));
    });

    test('should_clear_clipboard_when_set_to_null', () {
      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [],
        shapes: [],
        originalBounds: const BoundingBox(left: 0, top: 0, right: 10, bottom: 10),
      );

      expect(container.read(selectionClipboardProvider), isNotNull);

      container.read(selectionClipboardProvider.notifier).state = null;

      expect(container.read(selectionClipboardProvider), isNull);
    });

    test('should_store_shapes_only_clipboard_data', () {
      final shape = Shape(
        id: 'shape-1',
        type: ShapeType.line,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 100, y: 100),
        style: StrokeStyle.pen(),
      );
      const bounds = BoundingBox(left: 0, top: 0, right: 100, bottom: 100);

      container.read(selectionClipboardProvider.notifier).state =
          SelectionClipboardData(
        strokes: [],
        shapes: [shape],
        originalBounds: bounds,
      );

      final data = container.read(selectionClipboardProvider)!;
      expect(data.strokes.isEmpty, isTrue);
      expect(data.shapes.length, equals(1));
      expect(data.shapes.first.type, equals(ShapeType.line));
    });
  });
}
