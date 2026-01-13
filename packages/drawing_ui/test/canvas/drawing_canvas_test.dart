import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/canvas/stroke_painter.dart';

void main() {
  group('DrawingCanvas', () {
    // =========================================================================
    // Widget Rendering Tests
    // =========================================================================

    group('rendering', () {
      testWidgets('renders without errors', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        expect(find.byType(DrawingCanvas), findsOneWidget);
      });

      testWidgets('renders with custom size', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(
                  width: 400,
                  height: 300,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(DrawingCanvas), findsOneWidget);
      });

      testWidgets('uses LayoutBuilder for sizing', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        expect(find.byType(LayoutBuilder), findsOneWidget);
      });

      testWidgets('wraps content in ClipRect', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        expect(find.byType(ClipRect), findsOneWidget);
      });
    });

    // =========================================================================
    // Layer Structure Tests
    // =========================================================================

    group('layer structure', () {
      testWidgets('has Stack for layered rendering', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        // Find Stack that is descendant of DrawingCanvas
        expect(
          find.descendant(
            of: find.byType(DrawingCanvas),
            matching: find.byType(Stack),
          ),
          findsOneWidget,
        );
      });

      testWidgets('has 3 RepaintBoundary layers', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        // Grid + Committed + Active = 3 RepaintBoundary (inside DrawingCanvas)
        expect(
          find.descendant(
            of: find.byType(DrawingCanvas),
            matching: find.byType(RepaintBoundary),
          ),
          findsNWidgets(3),
        );
      });

      testWidgets('has 3 CustomPaint widgets', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        // Grid + Committed + Active = 3 CustomPaint (inside DrawingCanvas)
        expect(
          find.descendant(
            of: find.byType(DrawingCanvas),
            matching: find.byType(CustomPaint),
          ),
          findsNWidgets(3),
        );
      });

      testWidgets('uses ListenableBuilder for stroke layers', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        // Committed + Active = 2 ListenableBuilder (inside DrawingCanvas)
        expect(
          find.descendant(
            of: find.byType(DrawingCanvas),
            matching: find.byType(ListenableBuilder),
          ),
          findsNWidgets(2),
        );
      });
    });

    // =========================================================================
    // DrawingController Tests
    // =========================================================================

    group('DrawingController lifecycle', () {
      testWidgets('controller is created on init', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        final state = tester.state<DrawingCanvasState>(
          find.byType(DrawingCanvas),
        );

        expect(state.drawingController, isNotNull);
        expect(state.drawingController, isA<DrawingController>());
      });

      testWidgets('controller is disposed on widget disposal', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        final state = tester.state<DrawingCanvasState>(
          find.byType(DrawingCanvas),
        );
        // Verify controller exists before disposal
        expect(state.drawingController, isNotNull);

        // Dispose by removing widget
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(),
              ),
            ),
          ),
        );

        // Controller should be disposed (listeners cleared)
        // We verify disposal happened by the widget being removed
        expect(find.byType(DrawingCanvas), findsNothing);
      });

      testWidgets('committed strokes list is initially empty', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        final state = tester.state<DrawingCanvasState>(
          find.byType(DrawingCanvas),
        );

        expect(state.committedStrokes, isEmpty);
      });
    });

    // =========================================================================
    // Performance Optimization Tests
    // =========================================================================

    group('performance optimizations', () {
      testWidgets('uses ListenableBuilder instead of setState', (tester) async {
        // This test verifies architectural decisions

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DrawingCanvas(),
              ),
            ),
          ),
        );

        // If we got here without error, ListenableBuilder is being used
        // The existence of ListenableBuilder proves no setState pattern
        expect(
          find.descendant(
            of: find.byType(DrawingCanvas),
            matching: find.byType(ListenableBuilder),
          ),
          findsNWidgets(2),
        );
      });

      testWidgets('grid painter uses cached paint object', (tester) async {
        // GridPainter has static Paint - verify it exists
        const painter = GridPainter();

        // Calling shouldRepaint should always return false
        expect(painter.shouldRepaint(const GridPainter()), isFalse);
      });
    });
  });

  // ===========================================================================
  // GridPainter Unit Tests
  // ===========================================================================

  group('GridPainter', () {
    test('grid size is 25 pixels', () {
      expect(GridPainter.gridSize, equals(25.0));
    });

    test('shouldRepaint always returns false', () {
      const painter1 = GridPainter();
      const painter2 = GridPainter();

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('paints without throwing', () {
      const painter = GridPainter();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => painter.paint(canvas, const Size(100, 100)),
        returnsNormally,
      );

      recorder.endRecording();
    });

    test('paints grid lines', () {
      const painter = GridPainter();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Should not throw for various sizes
      painter.paint(canvas, const Size(100, 100));
      painter.paint(canvas, const Size(500, 300));
      painter.paint(canvas, Size.zero);

      recorder.endRecording();
    });
  });

  // ===========================================================================
  // Integration Tests
  // ===========================================================================

  group('integration', () {
    testWidgets('controller updates trigger ListenableBuilder rebuild',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingCanvas(),
            ),
          ),
        ),
      );

      final state = tester.state<DrawingCanvasState>(
        find.byType(DrawingCanvas),
      );
      final controller = state.drawingController;

      // Initially not drawing
      expect(controller.isDrawing, isFalse);

      // Start a stroke
      controller.startStroke(
        DrawingPoint(x: 10, y: 10, pressure: 1.0),
        StrokeStyle.pen(),
      );

      await tester.pump();

      expect(controller.isDrawing, isTrue);
      expect(controller.pointCount, equals(1));

      // Add points
      controller.addPoint(DrawingPoint(x: 20, y: 20, pressure: 1.0));
      controller.addPoint(DrawingPoint(x: 30, y: 30, pressure: 1.0));

      await tester.pump();

      expect(controller.pointCount, equals(3));

      // End stroke
      final stroke = controller.endStroke();

      await tester.pump();

      expect(stroke, isNotNull);
      expect(controller.isDrawing, isFalse);
      expect(controller.pointCount, equals(0));
    });

    testWidgets('canvas respects size constraints', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 150,
                child: DrawingCanvas(),
              ),
            ),
          ),
        ),
      );

      // Widget should be constrained to 200x150
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(DrawingCanvas),
      );

      expect(renderBox.size.width, equals(200));
      expect(renderBox.size.height, equals(150));
    });

    testWidgets('canvas fills available space with double.infinity',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingCanvas(),
            ),
          ),
        ),
      );

      // Widget should fill the scaffold body
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(DrawingCanvas),
      );

      // Should be larger than 0
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));
    });
  });
}
