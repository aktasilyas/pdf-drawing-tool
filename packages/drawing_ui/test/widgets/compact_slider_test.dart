import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/widgets/compact_slider.dart';

void main() {
  group('CompactSlider', () {
    testWidgets('renders title and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSlider(
              title: 'THICKNESS',
              value: 5.0,
              min: 1.0,
              max: 10.0,
              label: '5 pt',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('THICKNESS'), findsOneWidget);
      expect(find.text('5 pt'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('slider responds to value changes', (tester) async {
      double currentValue = 5.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CompactSlider(
                  title: 'TEST',
                  value: currentValue,
                  min: 1.0,
                  max: 10.0,
                  label: '${currentValue.toInt()} pt',
                  onChanged: (value) => setState(() => currentValue = value),
                );
              },
            ),
          ),
        ),
      );

      // Find the slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Verify initial value
      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.value, 5.0);
    });

    testWidgets('clamps value within min/max range', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSlider(
              title: 'TEST',
              value: 100.0, // Above max
              min: 1.0,
              max: 10.0,
              label: '100 pt',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 10.0); // Should be clamped to max
    });
  });
}
