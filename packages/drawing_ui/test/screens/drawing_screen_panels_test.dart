import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  testWidgets('buildActivePanel renders placeholder panels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: buildActivePanel(
                panel: ToolType.laserPointer,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Lazer işaretleyici'), findsOneWidget);
  });
}
