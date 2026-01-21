import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  testWidgets('CompactColorPicker renders tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CompactColorPicker(
              selectedColor: Colors.blue,
              onColorSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Renk paleti'), findsOneWidget);
    expect(find.text('Renk Seti'), findsOneWidget);
  });
}
