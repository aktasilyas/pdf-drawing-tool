import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final registry = DismissibleOverlays.instance;

  tearDown(registry.reset);

  test('dismissTopmost closes the most recent overlay first', () {
    final closed = <String>[];
    registry.register(() => closed.add('drawer'));
    registry.register(() => closed.add('popover'));

    expect(registry.dismissTopmost(), isTrue);
    expect(closed, ['popover']);
    expect(registry.dismissTopmost(), isTrue);
    expect(closed, ['popover', 'drawer']);
    expect(registry.dismissTopmost(), isFalse);
  });

  test('an unregistered overlay is no longer dismissed', () {
    var closed = 0;
    final unregister = registry.register(() => closed++);

    unregister();
    unregister();

    expect(registry.dismissTopmost(), isFalse);
    expect(closed, 0);
  });

  testWidgets('a showing popover is closed by dismissTopmost (system Back)',
      (tester) async {
    final controller = PopoverController();
    final anchorKey = GlobalKey();
    late BuildContext anchorContext;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          anchorContext = context;
          return Center(child: SizedBox(key: anchorKey, width: 40, height: 40));
        }),
      ),
    ));
    addTearDown(controller.dispose);

    controller.show(
      context: anchorContext,
      anchorKey: anchorKey,
      child: const SizedBox(key: Key('panel'), width: 100, height: 60),
    );
    await tester.pump();
    expect(find.byKey(const Key('panel')), findsOneWidget);

    expect(registry.dismissTopmost(), isTrue);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('panel')), findsNothing);
    expect(controller.isShowing, isFalse);
    expect(registry.isEmpty, isTrue);
  });

  testWidgets('a popover hidden by tapping outside unregisters itself',
      (tester) async {
    final controller = PopoverController();
    final anchorKey = GlobalKey();
    late BuildContext anchorContext;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          anchorContext = context;
          return Center(child: SizedBox(key: anchorKey, width: 40, height: 40));
        }),
      ),
    ));
    addTearDown(controller.dispose);

    controller.show(
      context: anchorContext,
      anchorKey: anchorKey,
      child: const SizedBox(width: 100, height: 60),
    );
    await tester.pump();
    controller.hide();
    await tester.pumpAndSettle();

    expect(registry.isEmpty, isTrue);
  });
}
