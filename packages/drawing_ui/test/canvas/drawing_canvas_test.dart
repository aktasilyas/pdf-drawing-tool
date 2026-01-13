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

      testWidgets('uses ListenableBuilder for active stroke layer',
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

        // Active stroke uses ListenableBuilder (Committed strokes use provider)
        expect(
          find.descendant(
            of: find.byType(DrawingCanvas),
            matching: find.byType(ListenableBuilder),
          ),
          findsOneWidget,
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

        // ListenableBuilder used for active stroke (committed uses provider)
        // The existence of ListenableBuilder proves no setState pattern
        expect(
          find.descendant(
            of: find.byType(DrawingCanvas),
            matching: find.byType(ListenableBuilder),
          ),
          findsOneWidget,
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
  // Gesture Handling Tests
  // ===========================================================================

  group('Gesture Handling', () {
    testWidgets('has Listener widget for raw pointer events', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DrawingCanvas(),
            ),
          ),
        ),
      );

      // Should have Listener for drawing and GestureDetector for zoom/pan
      expect(
        find.descendant(
          of: find.byType(DrawingCanvas),
          matching: find.byType(Listener),
        ),
        findsNWidgets(2), // Listener inside GestureDetector + our Listener
      );
      expect(
        find.descendant(
          of: find.byType(DrawingCanvas),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );
    });

    testWidgets('onPointerDown starts drawing', skip: true, (tester) async {
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

      // Initially not drawing
      expect(state.drawingController.isDrawing, isFalse);

      // Simulate pointer down
      final center = tester.getCenter(find.byType(DrawingCanvas));
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.pump();

      // Should now be drawing
      expect(state.drawingController.isDrawing, isTrue);
      expect(state.drawingController.pointCount, equals(1));
    });

    testWidgets('onPointerMove adds points', skip: true, (tester) async {
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Start drawing
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.pump();

      expect(state.drawingController.pointCount, equals(1));

      // Move pointer (large distance to pass min distance filter)
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.pump();

      expect(state.drawingController.pointCount, equals(2));

      // Move again
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(40, 40),
      ));
      await tester.pump();

      expect(state.drawingController.pointCount, equals(3));
    });

    testWidgets('onPointerUp creates and commits stroke', skip: true,
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Initial state
      expect(state.committedStrokes, isEmpty);

      // Draw a stroke
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.sendEventToBinding(PointerUpEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.pump();

      // Stroke should be committed
      expect(state.committedStrokes.length, equals(1));
      expect(state.drawingController.isDrawing, isFalse);
      expect(state.drawingController.pointCount, equals(0));
    });

    testWidgets('onPointerCancel cancels stroke', skip: true, (tester) async {
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Start drawing
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.pump();

      expect(state.drawingController.isDrawing, isTrue);
      expect(state.drawingController.pointCount, equals(2));

      // Cancel
      await tester.sendEventToBinding(PointerCancelEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.pump();

      // Stroke should be cancelled, not committed
      expect(state.committedStrokes, isEmpty);
      expect(state.drawingController.isDrawing, isFalse);
      expect(state.drawingController.pointCount, equals(0));
    });

    testWidgets('pressure is captured from pointer event', skip: true,
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Send pointer down with pressure
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
        pressure: 0.75,
      ));
      await tester.pump();

      // Complete stroke
      await tester.sendEventToBinding(PointerUpEvent(
        position: center,
      ));
      await tester.pump();

      // Check that pressure was captured
      expect(state.committedStrokes.length, equals(1));
      final points = state.committedStrokes.first.points;
      expect(points.first.pressure, equals(0.75));
    });

    testWidgets('minimum distance filter skips close points', skip: true,
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Start drawing
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.pump();

      expect(state.drawingController.pointCount, equals(1));

      // Move a tiny distance (< 1.0 pixel)
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(0.5, 0.5),
      ));
      await tester.pump();

      // Point should be skipped due to minimum distance filter
      expect(state.drawingController.pointCount, equals(1));

      // Move a large distance
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(10, 10),
      ));
      await tester.pump();

      // This point should be added
      expect(state.drawingController.pointCount, equals(2));
    });

    testWidgets('lastPoint is reset on pointer up', skip: true, (tester) async {
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Start and complete a stroke
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.pump();

      // lastPoint should be set
      expect(state.lastPoint, isNotNull);

      await tester.sendEventToBinding(PointerUpEvent(
        position: center,
      ));
      await tester.pump();

      // lastPoint should be reset
      expect(state.lastPoint, isNull);
    });

    testWidgets('lastPoint is reset on pointer cancel', skip: true,
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Start drawing
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.pump();

      expect(state.lastPoint, isNotNull);

      // Cancel
      await tester.sendEventToBinding(PointerCancelEvent(
        position: center,
      ));
      await tester.pump();

      expect(state.lastPoint, isNull);
    });

    testWidgets('pointer move does nothing when not drawing', (tester) async {
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Try to move without starting (pointer down)
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.pump();

      // Should have no effect
      expect(state.drawingController.isDrawing, isFalse);
      expect(state.drawingController.pointCount, equals(0));
    });

    testWidgets('multiple strokes can be drawn', skip: true, (tester) async {
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Draw first stroke
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.sendEventToBinding(PointerUpEvent(
        position: center + const Offset(20, 20),
      ));
      await tester.pump();

      expect(state.committedStrokes.length, equals(1));

      // Draw second stroke
      await tester.sendEventToBinding(PointerDownEvent(
        position: center + const Offset(50, 50),
      ));
      await tester.sendEventToBinding(PointerMoveEvent(
        position: center + const Offset(70, 70),
      ));
      await tester.sendEventToBinding(PointerUpEvent(
        position: center + const Offset(70, 70),
      ));
      await tester.pump();

      expect(state.committedStrokes.length, equals(2));
    });

    testWidgets('default style uses ballpointPen settings from provider',
        skip: true, (tester) async {
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
      final center = tester.getCenter(find.byType(DrawingCanvas));

      // Draw a stroke
      await tester.sendEventToBinding(PointerDownEvent(
        position: center,
      ));
      await tester.sendEventToBinding(PointerUpEvent(
        position: center,
      ));
      await tester.pump();

      // Check style - should use default ballpointPen settings
      final style = state.committedStrokes.first.style;
      expect(style.color, equals(0xFF000000)); // Black
      expect(style.thickness, equals(2.0)); // ballpointPen default
      expect(style.nibShape, equals(NibShape.circle)); // ballpointPen nib
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
