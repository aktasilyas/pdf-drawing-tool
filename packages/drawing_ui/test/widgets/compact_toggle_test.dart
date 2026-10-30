import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/widgets/compact_toggle.dart';

void main() {
  group('CompactToggle', () {
    testWidgets('renders label and switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactToggle(
              label: 'Pressure sensitivity',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pressure sensitivity'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('switch responds to taps', (tester) async {
      bool currentValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CompactToggle(
                  label: 'Test Toggle',
                  value: currentValue,
                  onChanged: (value) => setState(() => currentValue = value),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(currentValue, false);

      // Tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Value should change
      expect(currentValue, true);
    });

    testWidgets('displays correct initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactToggle(
              label: 'Test',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('is at least 48dp tall', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactToggle(
              label: 'Test',
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CompactToggle));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('tapping the label flips the value once', (tester) async {
      final calls = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactToggle(
              label: 'Test Toggle',
              value: false,
              onChanged: calls.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Toggle'));
      await tester.pump();
      expect(calls, [true]);
    });

    testWidgets('tapping the switch calls onChanged once', (tester) async {
      final calls = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactToggle(
              label: 'Test Toggle',
              value: true,
              onChanged: calls.add,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(calls, [false]);
    });

    testWidgets('row is one labelled switch node with on/off state',
        (tester) async {
      final handle = tester.ensureSemantics();
      var value = false;
      final calls = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => CompactToggle(
                label: 'Pressure sensitivity',
                value: value,
                onChanged: (v) {
                  calls.add(v);
                  setState(() => value = v);
                },
              ),
            ),
          ),
        ),
      );

      final node = find.bySemanticsLabel('Pressure sensitivity');
      expect(node, findsOneWidget);
      expect(
        tester.getSemantics(node),
        isSemantics(
          label: 'Pressure sensitivity',
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSize(find.byType(CompactToggle)).height,
        greaterThanOrEqualTo(48),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      // TalkBack double-tap runs the node's tap action: one toggle.
      tester.semantics.tap(find.semantics.byLabel('Pressure sensitivity'));
      await tester.pump();
      expect(calls, [true]);
      expect(
        tester.getSemantics(node),
        isSemantics(
          label: 'Pressure sensitivity',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });
}
