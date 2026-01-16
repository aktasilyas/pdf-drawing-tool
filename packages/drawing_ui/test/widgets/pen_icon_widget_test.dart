import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('PenIconWidget', () {
    testWidgets('renders without error for all pen types', (tester) async {
      for (final penType in core.PenType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PenIconWidget(
                penType: penType,
                color: Colors.black,
              ),
            ),
          ),
        );

        // Verify PenIconWidget is rendered
        expect(find.byType(PenIconWidget), findsOneWidget);
      }
    });

    testWidgets('respects size parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PenIconWidget(
              penType: core.PenType.pencil,
              size: 100,
            ),
          ),
        ),
      );

      final penIconWidget =
          tester.widget<PenIconWidget>(find.byType(PenIconWidget));
      expect(penIconWidget.size, 100);
    });

    testWidgets('passes color to widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PenIconWidget(
              penType: core.PenType.highlighter,
              color: Colors.yellow,
            ),
          ),
        ),
      );

      final penIconWidget =
          tester.widget<PenIconWidget>(find.byType(PenIconWidget));
      expect(penIconWidget.color, Colors.yellow);
    });

    testWidgets('passes isSelected to widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PenIconWidget(
              penType: core.PenType.brushPen,
              isSelected: true,
            ),
          ),
        ),
      );

      final penIconWidget =
          tester.widget<PenIconWidget>(find.byType(PenIconWidget));
      expect(penIconWidget.isSelected, isTrue);
    });

    testWidgets('default values are set correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PenIconWidget(
              penType: core.PenType.ballpointPen,
            ),
          ),
        ),
      );

      final penIconWidget =
          tester.widget<PenIconWidget>(find.byType(PenIconWidget));
      expect(penIconWidget.color, Colors.black);
      expect(penIconWidget.isSelected, isFalse);
      expect(penIconWidget.size, 56.0);
    });
  });

  group('ToolPenIcon', () {
    testWidgets('renders PenIconWidget for pen tools', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolPenIcon(toolType: ToolType.pencil),
          ),
        ),
      );

      expect(find.byType(PenIconWidget), findsOneWidget);
    });

    testWidgets('renders placeholder for non-pen tools', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolPenIcon(toolType: ToolType.shapes),
          ),
        ),
      );

      expect(find.byType(PenIconWidget), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('uses custom color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolPenIcon(
              toolType: ToolType.ballpointPen,
              color: Colors.blue,
            ),
          ),
        ),
      );

      final penIconWidget =
          tester.widget<PenIconWidget>(find.byType(PenIconWidget));
      expect(penIconWidget.color, Colors.blue);
    });

    testWidgets('passes size to PenIconWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolPenIcon(
              toolType: ToolType.gelPen,
              size: 80,
            ),
          ),
        ),
      );

      final penIconWidget =
          tester.widget<PenIconWidget>(find.byType(PenIconWidget));
      expect(penIconWidget.size, 80);
    });

    testWidgets('passes isSelected to PenIconWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ToolPenIcon(
              toolType: ToolType.brushPen,
              isSelected: true,
            ),
          ),
        ),
      );

      final penIconWidget =
          tester.widget<PenIconWidget>(find.byType(PenIconWidget));
      expect(penIconWidget.isSelected, isTrue);
    });
  });
}
