// Stylus mode (#507): one finger pans and swipes pages, two fingers still
// zoom, and the pen pre-empts a one-finger pan.
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  final swipes = <int>[];

  Future<void> pump(WidgetTester tester, {core.CanvasMode? mode}) async {
    swipes.clear();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(canvasMode: mode, onPageSwipe: swipes.add),
          ),
        ),
      ),
    );
    final finder = find.byType(DrawingCanvas);
    container = ProviderScope.containerOf(tester.element(finder));
  }

  /// Puts the canvas in stylus mode with a real pen stroke.
  Future<void> enterStylusMode(WidgetTester tester) async {
    final pen = await tester.startGesture(const Offset(100, 100),
        kind: PointerDeviceKind.stylus);
    await pen.moveBy(const Offset(40, 0));
    await pen.up();
    await tester.pump();
    expect(container.read(inputModeProvider).fingerDraws, isFalse);
  }

  const fixed = core.CanvasMode(isInfinite: false);

  testWidgets('one finger drag pans and adds no content', (tester) async {
    await pump(tester);
    await enterStylusMode(tester);
    final strokes = container.read(activeLayerStrokesProvider).length;
    final undo = container.read(undoCountProvider);
    final before = container.read(canvasTransformProvider).offset;

    final finger = await tester.startGesture(const Offset(300, 300));
    await finger.moveBy(const Offset(0, 40));
    await finger.moveBy(const Offset(0, 40));
    await finger.up();
    await tester.pump();

    expect(container.read(canvasTransformProvider).offset, isNot(before));
    expect(container.read(activeLayerStrokesProvider), hasLength(strokes));
    expect(container.read(undoCountProvider), undo);
  });

  testWidgets('one finger horizontal swipe calls onPageSwipe', (tester) async {
    await pump(tester, mode: fixed);
    await enterStylusMode(tester);

    final finger = await tester.startGesture(const Offset(500, 300));
    for (var i = 0; i < 8; i++) {
      await finger.moveBy(const Offset(-30, 0));
    }
    await tester.pump(const Duration(milliseconds: 16));
    await finger.up();
    await tester.pumpAndSettle();

    expect(swipes, [1]);
  });

  testWidgets('two finger pinch still zooms in stylus mode', (tester) async {
    await pump(tester);
    await enterStylusMode(tester);
    final before = container.read(canvasTransformProvider).zoom;

    final a = await tester.startGesture(const Offset(300, 300));
    final b = await tester.startGesture(const Offset(400, 300));
    for (var i = 0; i < 6; i++) {
      await a.moveBy(const Offset(-20, 0));
      await b.moveBy(const Offset(20, 0));
    }
    await a.up();
    await b.up();
    await tester.pump();

    expect(container.read(canvasTransformProvider).zoom, greaterThan(before));
  });

  testWidgets('pen down during a one-finger pan stops it and draws',
      (tester) async {
    await pump(tester);
    await enterStylusMode(tester);
    final strokes = container.read(activeLayerStrokesProvider).length;

    final finger = await tester.startGesture(const Offset(300, 300));
    await finger.moveBy(const Offset(0, 40));
    await finger.moveBy(const Offset(0, 40));
    final panned = container.read(canvasTransformProvider).offset;

    final pen = await tester.startGesture(const Offset(100, 500),
        kind: PointerDeviceKind.stylus);
    await finger.moveBy(const Offset(0, 40));
    for (var i = 0; i < 10; i++) {
      await pen.moveBy(const Offset(10, 0));
    }
    await pen.up();
    await finger.up();
    await tester.pump();

    expect(container.read(canvasTransformProvider).offset, panned);
    expect(container.read(activeLayerStrokesProvider), hasLength(strokes + 1));
  });

  testWidgets('without a stylus a one-finger drag draws, not pans',
      (tester) async {
    await pump(tester);
    final before = container.read(canvasTransformProvider).offset;

    final finger = await tester.startGesture(const Offset(100, 300));
    for (var i = 0; i < 10; i++) {
      await finger.moveBy(const Offset(10, 0));
    }
    await finger.up();
    await tester.pump();

    expect(container.read(canvasTransformProvider).offset, before);
    expect(container.read(activeLayerStrokesProvider), hasLength(1));
  });
}
