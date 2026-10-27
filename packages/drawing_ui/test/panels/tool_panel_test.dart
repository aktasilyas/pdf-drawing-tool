import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  group('ToolPanel', () {
    testWidgets('shows the title and calls onClose', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        _host(
          ToolPanel(
            title: 'Pen',
            onClose: () => closed++,
            child: const Text('Body'),
          ),
        ),
      );

      expect(find.text('Pen'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);

      await tester.tap(find.byType(PanelCloseButton));
      expect(closed, 1);
    });

    testWidgets('has no close button without onClose', (tester) async {
      await tester.pumpWidget(
        _host(const ToolPanel(title: 'Pen', child: SizedBox())),
      );

      expect(find.byType(PanelCloseButton), findsNothing);
    });

    testWidgets('fits a landscape phone without overflow', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(780, 360);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          const ToolPanel(
            title: 'Pen',
            child: SizedBox(height: 1000),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final height = tester.getSize(find.byType(ToolPanel)).height;
      expect(height, lessThanOrEqualTo(360 * 0.85));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('PanelSection', () {
    testWidgets('renders its title and child', (tester) async {
      await tester.pumpWidget(
        _host(
          const PanelSection(title: 'THICKNESS', child: Text('Slider')),
        ),
      );

      expect(find.text('THICKNESS'), findsOneWidget);
      expect(find.text('Slider'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
    });

    testWidgets('locked section shows the badge and taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PanelSection(
            title: 'MODE',
            isLocked: true,
            onLockedTap: () => taps++,
            child: const SizedBox(width: 200, height: 80),
          ),
        ),
      );

      expect(find.text('PRO'), findsOneWidget);
      await tester.tap(find.text('Premium'));
      expect(taps, 1);
    });
  });

  group('PanelToggleRow', () {
    testWidgets('reports the new value when toggled', (tester) async {
      bool? received;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 280,
            child: PanelToggleRow(
              label: 'Straight line',
              value: false,
              onChanged: (v) => received = v,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      expect(received, isTrue);
    });

    testWidgets('ignores taps when disabled', (tester) async {
      bool? received;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 280,
            child: PanelToggleRow(
              label: 'Straight line',
              value: false,
              enabled: false,
              onChanged: (v) => received = v,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      expect(received, isNull);
    });
  });

  group('PanelActionButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          PanelActionButton(
            label: 'Clear page',
            icon: Icons.delete_outline,
            isDestructive: true,
            onPressed: () => pressed++,
          ),
        ),
      );

      await tester.tap(find.text('Clear page'));
      expect(pressed, 1);
    });
  });

  group('touch targets', () {
    testWidgets('close and action buttons are at least 48dp', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PanelCloseButton(onTap: () {}),
              PanelActionButton(label: 'Ok', onPressed: () {}),
            ],
          ),
        ),
      );

      for (final type in [PanelCloseButton, PanelActionButton]) {
        final size = tester.getSize(find.byType(type));
        expect(size.width, greaterThanOrEqualTo(48), reason: '$type');
        expect(size.height, greaterThanOrEqualTo(48), reason: '$type');
      }
    });
  });
}
