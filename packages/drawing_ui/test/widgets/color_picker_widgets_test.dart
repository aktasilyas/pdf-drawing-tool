import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  testWidgets('color picker widgets build', (tester) async {
    final hsv = HSVColor.fromColor(Colors.red);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HSVPickerBox(
                hsvColor: hsv,
                onColorChanged: (_) {},
              ),
              HueSlider(
                hue: hsv.hue,
                onChanged: (_) {},
              ),
              OpacitySlider(
                color: Colors.blue,
                opacity: 0.5,
                onChanged: (_) {},
              ),
              HexOpacityInput(
                color: Colors.green,
                opacity: 0.75,
                showOpacity: true,
                onColorChanged: (_) {},
                onSave: () {},
              ),
              RecentColorsRow(
                colors: const [Colors.red, Colors.green, Colors.blue],
                selectedColor: Colors.red,
                onColorSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(HSVPickerBox), findsOneWidget);
    expect(find.byType(HueSlider), findsOneWidget);
    expect(find.byType(OpacitySlider), findsOneWidget);
    expect(find.byType(HexOpacityInput), findsOneWidget);
    expect(find.byType(RecentColorsRow), findsOneWidget);
  });
}
