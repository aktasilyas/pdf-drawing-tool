import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/widgets/export_saved_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, ExportProgressState state) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ExportSavedBody(state: state, cs: const ColorScheme.light()),
      ),
    ),
  );
}

void main() {
  const strings = ExportStringsTr();

  testWidgets('warns about pages exported without their PDF', (tester) async {
    await _pump(
      tester,
      const ExportProgressState(
        status: ExportProgressStatus.completed,
        fileSize: '1.0 MB',
        pagesMissingBackground: 2,
      ),
    );

    expect(find.text(strings.savedWithSize('1.0 MB')), findsOneWidget);
    expect(find.text(strings.pagesWithoutPdfBackground(2)), findsOneWidget);
  });

  testWidgets('warns about pages with unreadable images', (tester) async {
    await _pump(
      tester,
      const ExportProgressState(
        status: ExportProgressStatus.completed,
        fileSize: '1.0 MB',
        pagesMissingImages: 3,
      ),
    );

    expect(find.text(strings.pagesWithoutImages(3)), findsOneWidget);
    expect(find.text(strings.pagesWithoutPdfBackground(0)), findsNothing);
  });

  testWidgets('shows only the saved line when nothing is missing',
      (tester) async {
    await _pump(
      tester,
      const ExportProgressState(
        status: ExportProgressStatus.completed,
        fileSize: '1.0 MB',
      ),
    );

    expect(find.text(strings.savedWithSize('1.0 MB')), findsOneWidget);
    expect(find.text(strings.pagesWithoutPdfBackground(1)), findsNothing);
    expect(find.text(strings.pagesWithoutPdfBackground(0)), findsNothing);
    expect(find.text(strings.pagesWithoutImages(0)), findsNothing);
  });
}
