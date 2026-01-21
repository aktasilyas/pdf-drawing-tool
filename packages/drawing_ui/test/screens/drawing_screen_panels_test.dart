import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  test('resolvePanelAlignment uses expected edges', () {
    expect(resolvePanelAlignment(ToolType.pencil), AnchorAlignment.left);
    expect(resolvePanelAlignment(ToolType.laserPointer), AnchorAlignment.right);
    expect(resolvePanelAlignment(ToolType.selection), AnchorAlignment.center);
  });

  testWidgets('buildActivePanel renders placeholder panels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrawingThemeProvider(
            theme: const DrawingTheme(),
            child: buildActivePanel(
              panel: ToolType.laserPointer,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Laser Pointer'), findsOneWidget);
  });
}
