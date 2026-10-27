import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/widgets/floating_pen_box_controls.dart';
import 'package:drawing_ui/src/widgets/floating_pen_box_slot.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _blue = Color(0xFF1565C0);

const _presets = [
  PenPreset(id: 'ballpoint'),
  PenPreset(
    id: 'highlighter',
    toolType: ToolType.highlighter,
    color: Color(0xFFFFD54F),
  ),
  PenPreset(id: 'fountain', toolType: ToolType.fountainPen, color: _blue),
];

/// Default test view is 800x600 logical px: x=12 hugs the left edge (column),
/// x=200 near the top opens a row.
const _columnPosition = Offset(12, 12);
const _rowPosition = Offset(200, 12);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Offset position = _columnPosition,
  List<PenPreset> presets = _presets,
}) async {
  final container = ProviderContainer(
    overrides: [
      penBoxPresetsProvider
          .overrideWith((ref) => PenBoxPresetsNotifier(presets)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: FloatingPenBox(position: position),
          ),
        ),
      ),
    ),
  );
  return container;
}

Finder _slot(String id) => find.byWidgetPredicate(
      (w) => w is FloatingPenBoxSlot && w.preset.id == id,
    );

Future<void> _singleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  // A single tap resolves once the double-tap window has passed.
  await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders nothing without presets', (tester) async {
    await _pump(tester, presets: const []);
    expect(find.byType(FloatingPenBoxSlot), findsNothing);
  });

  testWidgets('column layout near the left edge', (tester) async {
    await _pump(tester);

    expect(find.byType(FloatingPenBoxSlot), findsNWidgets(3));
    final slots = tester.widgetList<FloatingPenBoxSlot>(
      find.byType(FloatingPenBoxSlot),
    );
    expect(slots.every((s) => s.boxAxis == Axis.vertical), isTrue);
    final first = tester.getTopLeft(_slot('ballpoint'));
    final second = tester.getTopLeft(_slot('highlighter'));
    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
  });

  testWidgets('row layout near the top', (tester) async {
    await _pump(tester, position: _rowPosition);

    final slots = tester.widgetList<FloatingPenBoxSlot>(
      find.byType(FloatingPenBoxSlot),
    );
    expect(slots.every((s) => s.boxAxis == Axis.horizontal), isTrue);
    final first = tester.getTopLeft(_slot('ballpoint'));
    final second = tester.getTopLeft(_slot('highlighter'));
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
  });

  for (final position in [_columnPosition, _rowPosition]) {
    testWidgets('every slot is a >= 48dp touch target at $position',
        (tester) async {
      await _pump(tester, position: position);
      for (final id in ['ballpoint', 'highlighter', 'fountain']) {
        final size = tester.getSize(_slot(id));
        expect(size.width, greaterThanOrEqualTo(48), reason: id);
        expect(size.height, greaterThanOrEqualTo(48), reason: id);
      }
    });
  }

  testWidgets('tapping a preset activates it', (tester) async {
    final container = await _pump(tester);

    await _singleTap(tester, _slot('fountain'));

    expect(container.read(selectedPresetIndexProvider), 2);
    expect(container.read(currentToolProvider), ToolType.fountainPen);
    expect(
      container.read(penSettingsProvider(ToolType.fountainPen)).color,
      _blue,
    );
    final slot = tester.widget<FloatingPenBoxSlot>(_slot('fountain'));
    expect(slot.isSelected, isTrue);
  });

  testWidgets('double-tapping a preset opens its editor', (tester) async {
    final container = await _pump(tester);

    await _doubleTap(tester, _slot('highlighter'));

    expect(container.read(activePanelProvider), ToolType.highlighter);
  });

  testWidgets('edit mode deletes a preset and ignores taps', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byIcon(ElyanotesIcons.editPencil));
    await tester.pumpAndSettle();
    expect(find.byIcon(ElyanotesIcons.minus), findsNWidgets(3));

    await _singleTap(tester, _slot('fountain'));
    expect(container.read(selectedPresetIndexProvider), 0);

    await _singleTap(
      tester,
      find.descendant(
        of: _slot('ballpoint'),
        matching: find.byIcon(ElyanotesIcons.minus),
      ),
    );

    expect(
      container.read(penBoxPresetsProvider).map((p) => p.id),
      ['highlighter', 'fountain'],
    );
    expect(_slot('ballpoint'), findsNothing);
  });

  testWidgets('collapses to a badge and expands again', (tester) async {
    await _pump(tester);

    await tester.tap(find.byIcon(ElyanotesIcons.caretUp));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingPenBoxSlot), findsNothing);
    expect(find.byType(FloatingPenBoxCollapsed), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byType(FloatingPenBoxCollapsed));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingPenBoxSlot), findsNWidgets(3));
  });

  testWidgets('dragging the collapsed box reports the delta', (tester) async {
    final deltas = <Offset>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          penBoxPresetsProvider
              .overrideWith((ref) => PenBoxPresetsNotifier(_presets)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: FloatingPenBox(onPositionChanged: deltas.add),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(ElyanotesIcons.caretUp));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(FloatingPenBoxCollapsed),
      const Offset(60, 40),
    );

    final total = deltas.fold(Offset.zero, (a, b) => a + b);
    expect(total.dx, greaterThan(0));
    expect(total.dy, greaterThan(0));
  });
}
