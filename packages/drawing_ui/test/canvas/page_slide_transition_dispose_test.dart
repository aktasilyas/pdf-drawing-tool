import 'dart:ui' as ui;

import 'package:drawing_ui/src/canvas/page_slide_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Snapshot images currently shown by the transition's overlay.
List<ui.Image> _shown(WidgetTester t) =>
    t.widgetList<RawImage>(find.byType(RawImage)).map((w) => w.image!).toList();

void _expectLive(List<ui.Image> images) {
  expect(images, isNotEmpty);
  for (final i in images) {
    expect(i.debugDisposed, isFalse);
  }
}

void _expectDisposed(List<ui.Image> images) {
  for (final i in images) {
    expect(i.debugDisposed, isTrue);
  }
}

void main() {
  final key = GlobalKey<PageSlideTransitionState>();

  Future<void> pump(WidgetTester t) => t.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 600,
            child: PageSlideTransition(
              key: key,
              child: const ColoredBox(color: Colors.white),
            ),
          ),
        ),
      );

  testWidgets('snapshots are disposed after a committed drag completes', (
    t,
  ) async {
    await pump(t);
    final s = key.currentState!;
    await t.runAsync(s.beginDrag);
    await t.pump();
    final imgs = _shown(t);
    _expectLive(imgs);
    s.updateDrag(-250);
    await t.pump();
    s.endDrag(0);
    await t.pumpAndSettle();
    await t.pump();
    _expectDisposed(imgs);
  });

  testWidgets('unmounting mid-drag disposes the drag snapshot', (t) async {
    await pump(t);
    final s = key.currentState!;
    await t.runAsync(s.beginDrag);
    await t.pump();
    s.updateDrag(-100);
    await t.pump();
    final imgs = _shown(t);
    _expectLive(imgs);
    await t.pumpWidget(const SizedBox());
    _expectDisposed(imgs);
  });

  testWidgets('unmounting mid drag-release animation disposes snapshot', (
    t,
  ) async {
    await pump(t);
    final s = key.currentState!;
    await t.runAsync(s.beginDrag);
    await t.pump();
    s.updateDrag(-250);
    await t.pump();
    s.endDrag(0);
    await t.pump(const Duration(milliseconds: 50));
    final imgs = _shown(t);
    _expectLive(imgs);
    await t.pumpWidget(const SizedBox());
    _expectDisposed(imgs);
  });

  testWidgets('unmounting mid auto-animation disposes snapshot', (t) async {
    await pump(t);
    final s = key.currentState!;
    await t.runAsync(() => s.captureSnapshot(forward: true));
    await t.pump();
    s.startAnimation();
    await t.pump(const Duration(milliseconds: 50));
    final imgs = _shown(t);
    _expectLive(imgs);
    await t.pumpWidget(const SizedBox());
    _expectDisposed(imgs);
  });

  testWidgets('snapshot is disposed after auto-animation completes', (t) async {
    await pump(t);
    final s = key.currentState!;
    await t.runAsync(() => s.captureSnapshot(forward: true));
    await t.pump();
    s.startAnimation();
    await t.pump(const Duration(milliseconds: 50));
    final imgs = _shown(t);
    _expectLive(imgs);
    await t.pumpAndSettle();
    _expectDisposed(imgs);
  });
}
