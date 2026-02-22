import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/widgets/pdf_export_dialog.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';

void main() {
  group('PDFExportDialog', () {
    testWidgets('should display dialog with Turkish title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const PDFExportDialog(totalPages: 5),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('PDF Olarak Disa Aktar'), findsOneWidget);
    });

    testWidgets('should display total pages count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 5)),
        ),
      );

      expect(find.text('5 sayfa'), findsOneWidget);
    });

    testWidgets('should display export mode options in Turkish', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 5)),
        ),
      );

      expect(find.text('Disa Aktarma Modu'), findsOneWidget);
      expect(find.text('Vektor'), findsOneWidget);
      expect(find.text('Raster'), findsOneWidget);
      expect(find.text('Karma'), findsOneWidget);
    });

    testWidgets('should display quality options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 5)),
        ),
      );

      expect(find.text('Kalite'), findsOneWidget);
      expect(find.text('Dusuk'), findsOneWidget);
      expect(find.text('Orta'), findsOneWidget);
      expect(find.text('Yuksek'), findsOneWidget);
      expect(find.text('Baski'), findsOneWidget);
    });

    testWidgets('should display page format section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 5)),
        ),
      );

      expect(find.text('Sayfa Formati'), findsOneWidget);
      expect(find.text('A4'), findsOneWidget);
    });

    testWidgets('should display background toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 5)),
        ),
      );

      expect(find.text('Arka plani dahil et'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('should toggle export mode on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 5)),
        ),
      );

      await tester.tap(find.text('Raster'));
      await tester.pump();

      expect(find.text('Raster'), findsOneWidget);
    });

    testWidgets('should display Turkish action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 5)),
        ),
      );

      expect(find.text('Iptal'), findsOneWidget);
      expect(find.text('Disa Aktar'), findsOneWidget);
    });

    testWidgets('should close dialog on cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const PDFExportDialog(totalPages: 5),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('PDF Olarak Disa Aktar'), findsOneWidget);

      await tester.tap(find.text('Iptal'));
      await tester.pumpAndSettle();

      expect(find.text('PDF Olarak Disa Aktar'), findsNothing);
    });

    testWidgets('should call onExport callback', (tester) async {
      PDFExportConfig? exportedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => PDFExportDialog(
                    totalPages: 3,
                    onExport: (config) => exportedConfig = config,
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

      await tester.tap(find.text('Disa Aktar'));
      await tester.pumpAndSettle();

      expect(exportedConfig, isNotNull);
      expect(exportedConfig!.exportMode, PDFExportMode.vector);
      expect(exportedConfig!.quality, PDFExportQuality.high);
      expect(exportedConfig!.includeBackground, true);
    });

    testWidgets('should not overflow on small screens', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PDFExportDialog(totalPages: 10)),
        ),
      );

      // No overflow errors expected — dialog uses SingleChildScrollView
      expect(tester.takeException(), isNull);
    });
  });

  group('PDFExportConfig', () {
    test('should create with default values', () {
      const config = PDFExportConfig();

      expect(config.exportMode, PDFExportMode.vector);
      expect(config.quality, PDFExportQuality.high);
      expect(config.includeBackground, true);
    });

    test('should create with custom values', () {
      const config = PDFExportConfig(
        exportMode: PDFExportMode.raster,
        quality: PDFExportQuality.medium,
        includeBackground: false,
      );

      expect(config.exportMode, PDFExportMode.raster);
      expect(config.quality, PDFExportQuality.medium);
      expect(config.includeBackground, false);
    });

    test('should convert to export options', () {
      const config = PDFExportConfig(
        exportMode: PDFExportMode.hybrid,
        quality: PDFExportQuality.low,
        includeBackground: false,
      );
      final options = config.toExportOptions();

      expect(options.exportMode, PDFExportMode.hybrid);
      expect(options.quality, PDFExportQuality.low);
      expect(options.includeBackground, false);
    });
  });

  group('ExportDialogResult', () {
    test('should create successful result', () {
      final result = ExportDialogResult.success(
        config: const PDFExportConfig(),
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
}
