import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _overlayTests();
  _selectionToolbarTests();
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

void _overlayTests() {
  final registry = DismissibleOverlays.instance;

  tearDown(registry.reset);

  testWidgets('ColorPickerStrip palette is closed by dismissTopmost',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ColorPickerStrip(
            selectedColor: Colors.black,
            onColorSelected: (_) {},
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(ChromeIconButton).last);
    await tester.pump();
    expect(find.byType(CompactColorPicker), findsOneWidget);

    expect(registry.dismissTopmost(), isTrue);
    await tester.pump();

    expect(find.byType(CompactColorPicker), findsNothing);
    expect(registry.isEmpty, isTrue);
  });

  testWidgets('palette opened above a popover closes before the popover',
      (tester) async {
    final controller = PopoverController();
    final anchorKey = GlobalKey();
    late BuildContext anchorContext;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            anchorContext = context;
            return Center(
                child: SizedBox(key: anchorKey, width: 40, height: 40));
          }),
        ),
      ),
    ));
    addTearDown(controller.dispose);
    controller.show(
      context: anchorContext,
      anchorKey: anchorKey,
      child: ColorPickerStrip(
        selectedColor: Colors.black,
        onColorSelected: (_) {},
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(ChromeIconButton).last);
    await tester.pump();
    expect(find.byType(CompactColorPicker), findsOneWidget);

    expect(registry.dismissTopmost(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(CompactColorPicker), findsNothing);
    expect(find.byType(ColorPickerStrip), findsOneWidget);

    expect(registry.dismissTopmost(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(ColorPickerStrip), findsNothing);
  });

  testWidgets('UnifiedColorPicker palette is closed by dismissTopmost',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: UnifiedColorPicker(
            selectedColor: Colors.black,
            onColorSelected: (_) {},
          ),
        ),
      ),
    ));
    await tester.tap(find.byIcon(ElyanotesIcons.palette));
    await tester.pump();

    expect(registry.dismissTopmost(), isTrue);
    await tester.pump();
    expect(registry.isEmpty, isTrue);
  });

  testWidgets('DismissibleOverlayEntry.close is idempotent', (tester) async {
    late OverlayState overlay;
    var closedCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        overlay = Overlay.of(context);
        return const SizedBox();
      }),
    ));
    final entry = DismissibleOverlayEntry.show(
      overlay,
      (_) => const SizedBox(key: Key('o')),
      onClosed: () => closedCalls++,
    );
    await tester.pump();
    expect(find.byKey(const Key('o')), findsOneWidget);

    entry.close();
    entry.close();
    await tester.pump();

    expect(find.byKey(const Key('o')), findsNothing);
    expect(closedCalls, 1);
    expect(registry.dismissTopmost(), isFalse);
  });
}

void _selectionToolbarTests() {
  final registry = DismissibleOverlays.instance;

  tearDown(registry.reset);

  testWidgets('selection overflow menu is closed by dismissTopmost',
      (tester) async {
    final selection = Selection.create(
      type: SelectionType.rectangle,
      selectedStrokeIds: ['s1'],
      bounds: const BoundingBox(left: 100, top: 100, right: 200, bottom: 200),
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
            body: Stack(children: [SelectionToolbar(selection: selection)])),
      ),
    ));
    await tester.pump();
    final more = find.byIcon(ElyanotesIcons.more);
    expect(more, findsOneWidget);

    await tester.tap(more);
    await tester.pump();
    expect(find.byType(SelectionOverflowMenu), findsOneWidget);

    expect(registry.dismissTopmost(), isTrue);
    await tester.pump();

    expect(find.byType(SelectionOverflowMenu), findsNothing);
    expect(registry.isEmpty, isTrue);
  });
}
