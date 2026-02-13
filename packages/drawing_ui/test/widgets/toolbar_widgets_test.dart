import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  Widget buildWithTheme(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: DrawingThemeProvider(
          theme: const DrawingTheme(),
          child: child,
        ),
      ),
    );
  }

  testWidgets('ToolbarUndoRedoButtons renders icons', (tester) async {
    await tester.pumpWidget(
      buildWithTheme(
        const ToolbarUndoRedoButtons(
          canUndo: true,
          canRedo: false,
        ),
      ),
    );

    expect(find.byIcon(StarNoteIcons.undo), findsOneWidget);
    expect(find.byIcon(StarNoteIcons.redo), findsOneWidget);
  });

  testWidgets('ToolbarVerticalDivider renders', (tester) async {
    await tester.pumpWidget(buildWithTheme(const ToolbarVerticalDivider()));
    expect(find.byType(ToolbarVerticalDivider), findsOneWidget);
  });

  testWidgets('ToolbarIconButton renders with tooltip', (tester) async {
    await tester.pumpWidget(
      buildWithTheme(
        const ToolbarIconButton(
          icon: StarNoteIcons.pencil,
          tooltip: 'Edit',
          enabled: true,
        ),
      ),
    );

    expect(find.byTooltip('Edit'), findsOneWidget);
  });
}
