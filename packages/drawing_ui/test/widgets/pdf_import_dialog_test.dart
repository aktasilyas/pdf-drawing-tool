import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/widgets/pdf_import_dialog.dart';

void main() {
  group('PDFImportDialog', () {
    testWidgets('should display dialog with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const PDFImportDialog(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Import PDF'), findsOneWidget);
    });

    testWidgets('should display file picker button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(),
          ),
        ),
      );

      expect(find.text('Select PDF File'), findsOneWidget);
    });

    testWidgets('should display cancel button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should close dialog on cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const PDFImportDialog(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Import PDF'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Import PDF'), findsNothing);
    });

    testWidgets('should disable import button when no file selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(),
          ),
        ),
      );

      final importButton = find.widgetWithText(ElevatedButton, 'Import');
      expect(importButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(importButton);
      expect(button.onPressed, isNull);
    });
  });

  group('PDFImportOptions', () {
    testWidgets('should display import options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(),
          ),
        ),
      );

      expect(find.text('Import Options'), findsOneWidget);
    });

    testWidgets('should display all pages option', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(),
          ),
        ),
      );

      expect(find.text('Import all pages'), findsOneWidget);
    });

    testWidgets('should display page range option', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(),
          ),
        ),
      );

      expect(find.text('Select page range'), findsOneWidget);
    });

    testWidgets('should toggle between all pages and range', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(),
          ),
        ),
      );

      // Initially all pages should be selected
      final allPagesRadio = find.byType(RadioListTile<PDFImportMode>).first;
      RadioListTile<PDFImportMode> radioWidget = tester.widget(allPagesRadio);
      expect(radioWidget.value, PDFImportMode.allPages);

      // Tap on page range option
      await tester.tap(find.text('Select page range'));
      await tester.pump();

      // Now page range should be selected
      RadioListTile<PDFImportMode> updatedWidget = tester.widget(allPagesRadio.at(1));
      expect(updatedWidget.selected, true);
    });
  });

  group('PDFImportProgress', () {
    testWidgets('should show loading indicator during import', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display progress message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(
              isLoading: true,
              progressMessage: 'Loading PDF...',
            ),
          ),
        ),
      );

      expect(find.text('Loading PDF...'), findsOneWidget);
    });

    testWidgets('should disable buttons during import', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(isLoading: true),
          ),
        ),
      );

      final selectButton = find.widgetWithText(ElevatedButton, 'Select PDF File');
      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      final importButton = find.widgetWithText(ElevatedButton, 'Import');

      expect(tester.widget<ElevatedButton>(selectButton).onPressed, isNull);
      expect(tester.widget<TextButton>(cancelButton).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(importButton).onPressed, isNull);
    });
  });

  group('PDFImportError', () {
    testWidgets('should display error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(
              errorMessage: 'Failed to load PDF',
            ),
          ),
        ),
      );

      expect(find.text('Failed to load PDF'), findsOneWidget);
    });

    testWidgets('should display error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(
              errorMessage: 'Error',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should allow retry after error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFImportDialog(
              errorMessage: 'Failed to load PDF',
            ),
          ),
        ),
      );

      expect(find.text('Select PDF File'), findsOneWidget);
      
      final selectButton = find.widgetWithText(ElevatedButton, 'Select PDF File');
      expect(tester.widget<ElevatedButton>(selectButton).onPressed, isNotNull);
    });
  });

  group('PDFImportResult', () {
    test('should create successful result', () {
      final result = PDFImportResult.success(pageCount: 5);

      expect(result.isSuccess, true);
      expect(result.pageCount, 5);
      expect(result.errorMessage, isNull);
    });

    test('should create error result', () {
      final result = PDFImportResult.error('File not found');

      expect(result.isSuccess, false);
      expect(result.pageCount, 0);
      expect(result.errorMessage, 'File not found');
    });

    test('should create cancelled result', () {
      final result = PDFImportResult.cancelled();

      expect(result.isSuccess, false);
      expect(result.pageCount, 0);
      expect(result.errorMessage, isNull);
    });
  });

  group('PDFImportMode', () {
    test('should have allPages mode', () {
      expect(PDFImportMode.allPages, isNotNull);
    });

    test('should have pageRange mode', () {
      expect(PDFImportMode.pageRange, isNotNull);
    });

    test('should have selectedPages mode', () {
      expect(PDFImportMode.selectedPages, isNotNull);
    });
  });

  group('PageRangeSelector', () {
    testWidgets('should display start page input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageRangeSelector(
              totalPages: 10,
              startPage: 1,
              endPage: 10,
              onRangeChanged: null,
            ),
          ),
        ),
      );

      expect(find.text('From'), findsOneWidget);
    });

    testWidgets('should display end page input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageRangeSelector(
              totalPages: 10,
              startPage: 1,
              endPage: 10,
              onRangeChanged: null,
            ),
          ),
        ),
      );

      expect(find.text('To'), findsOneWidget);
    });

    testWidgets('should display total pages info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageRangeSelector(
              totalPages: 10,
              startPage: 1,
              endPage: 10,
              onRangeChanged: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('10 pages'), findsOneWidget);
    });
  });
}
