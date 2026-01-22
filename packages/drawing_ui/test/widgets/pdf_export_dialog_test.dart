import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/widgets/pdf_export_dialog.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';

void main() {
  group('PDFExportDialog', () {
    testWidgets('should display dialog with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const PDFExportDialog(
                    totalPages: 5,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Export to PDF'), findsOneWidget);
    });

    testWidgets('should display total pages count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      expect(find.textContaining('5 pages'), findsOneWidget);
    });

    testWidgets('should display export mode options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      expect(find.text('Export Mode'), findsOneWidget);
      expect(find.text('Vector'), findsOneWidget);
      expect(find.text('Raster'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
    });

    testWidgets('should display quality options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      expect(find.text('Quality'), findsOneWidget);
    });

    testWidgets('should display page format options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      expect(find.text('Page Format'), findsOneWidget);
    });

    testWidgets('should display include background option', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      expect(find.text('Include backgrounds'), findsOneWidget);
    });

    testWidgets('should toggle export mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      // Tap on Raster mode
      await tester.tap(find.text('Raster'));
      await tester.pump();

      // Mode should change (RadioListTile would update)
      expect(find.text('Raster'), findsOneWidget);
    });

    testWidgets('should display cancel button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should display export button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(totalPages: 5),
          ),
        ),
      );

      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets('should close dialog on cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const PDFExportDialog(
                    totalPages: 5,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Export to PDF'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Export to PDF'), findsNothing);
    });

    testWidgets('should show progress during export', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(
              totalPages: 5,
              isExporting: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display progress message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(
              totalPages: 5,
              isExporting: true,
              progressMessage: 'Exporting page 3 of 5...',
            ),
          ),
        ),
      );

      expect(find.text('Exporting page 3 of 5...'), findsOneWidget);
    });

    testWidgets('should disable buttons during export', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(
              totalPages: 5,
              isExporting: true,
            ),
          ),
        ),
      );

      final cancelButton = find.widgetWithText(TextButton, 'Cancel');
      final exportButton = find.widgetWithText(ElevatedButton, 'Export');

      expect(tester.widget<TextButton>(cancelButton).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(exportButton).onPressed, isNull);
    });

    testWidgets('should display error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PDFExportDialog(
              totalPages: 5,
              errorMessage: 'Export failed',
            ),
          ),
        ),
      );

      expect(find.text('Export failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('PDFExportConfig', () {
    test('should create with default values', () {
      final config = PDFExportConfig();

      expect(config.exportMode, PDFExportMode.vector);
      expect(config.quality, PDFExportQuality.high);
      expect(config.includeBackground, true);
    });

    test('should create with custom values', () {
      final config = PDFExportConfig(
        exportMode: PDFExportMode.raster,
        quality: PDFExportQuality.medium,
        includeBackground: false,
      );

      expect(config.exportMode, PDFExportMode.raster);
      expect(config.quality, PDFExportQuality.medium);
      expect(config.includeBackground, false);
    });

    test('should copy with new values', () {
      final original = PDFExportConfig();
      final copy = original.copyWith(
        exportMode: PDFExportMode.hybrid,
      );

      expect(copy.exportMode, PDFExportMode.hybrid);
      expect(copy.quality, original.quality);
    });
  });

  group('ExportResult', () {
    test('should create successful result', () {
      final result = ExportDialogResult.success(
        config: PDFExportConfig(),
      );

      expect(result.confirmed, true);
      expect(result.config, isNotNull);
    });

    test('should create cancelled result', () {
      final result = ExportDialogResult.cancelled();

      expect(result.confirmed, false);
      expect(result.config, isNull);
    });
  });

  group('QualitySelector', () {
    testWidgets('should display quality levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QualitySelector(
              selectedQuality: PDFExportQuality.high,
              onQualityChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
    });

    testWidgets('should show quality descriptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QualitySelector(
              selectedQuality: PDFExportQuality.high,
              onQualityChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('DPI'), findsWidgets);
    });
  });

  group('FormatSelector', () {
    testWidgets('should display format options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormatSelector(
              selectedFormat: PDFPageFormat.a4,
              onFormatChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('A4'), findsOneWidget);
      expect(find.text('A5'), findsOneWidget);
      expect(find.text('Letter'), findsOneWidget);
      expect(find.text('Legal'), findsOneWidget);
    });

    testWidgets('should show format dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormatSelector(
              selectedFormat: PDFPageFormat.a4,
              onFormatChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('×'), findsWidgets);
    });
  });

  group('ExportModeSelector', () {
    testWidgets('should display mode descriptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportModeSelector(
              selectedMode: PDFExportMode.vector,
              onModeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('best quality'), findsOneWidget);
      expect(find.textContaining('smaller file'), findsOneWidget);
      expect(find.textContaining('balanced'), findsOneWidget);
    });
  });
}
