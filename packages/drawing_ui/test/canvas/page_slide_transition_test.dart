import 'package:drawing_ui/src/canvas/page_slide_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final key = GlobalKey<PageSlideTransitionState>();
  final navigated = <int>[];
  var reverted = 0;

  Future<void> pump(WidgetTester t,
      {bool preSwitch = false, Widget? addPreview, bool fwd = true}) async {
    await t.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 600,
        child: PageSlideTransition(
          key: key,
          canSwipeForward: fwd,
          addPagePreview: addPreview,
          onSwipeNavigate: navigated.add,
          onDragDirectionDetermined: (_) => preSwitch,
          onDragReverted: () => reverted++,
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    ));
  }

  Future<void> drag(WidgetTester t, double dx, double velocity) async {
    final s = key.currentState!;
    await t.runAsync(s.beginDrag);
    await t.pump();
    s.updateDrag(dx);
    await t.pump();
    s.endDrag(velocity);
    await t.pumpAndSettle();
    await t.pump();
  }

  setUp(() {
    navigated.clear();
    reverted = 0;
  });

  testWidgets('forward drag past threshold navigates +1', (t) async {
    await pump(t);
    await drag(t, -250, 0);
    expect(navigated, [1]);
    expect(reverted, 0);
  });

  testWidgets('short drag does not navigate', (t) async {
    await pump(t);
    await drag(t, -30, 0);
    expect(navigated, isEmpty);
  });

  testWidgets('short pre-switched drag calls onDragReverted', (t) async {
    await pump(t, preSwitch: true);
    await drag(t, -40, 0);
    expect(navigated, isEmpty);
    expect(reverted, 1);
  });

  testWidgets('add-page preview is shown during forward drag', (t) async {
    await pump(t, addPreview: const Text('add page'));
    final s = key.currentState!;
    await t.runAsync(s.beginDrag);
    await t.pump();
    s.updateDrag(-100);
    await t.pump();
    expect(find.text('add page'), findsOneWidget);
    s.endDrag(0);
    await t.pumpAndSettle();
  });

  testWidgets('drag state is reset and widget disposes cleanly', (t) async {
    await pump(t);
    await drag(t, -250, 0);
    expect(find.byType(RawImage), findsNothing);
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });
}
