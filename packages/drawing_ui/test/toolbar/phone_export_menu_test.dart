import 'package:drawing_core/drawing_core.dart' show DrawingDocument;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../golden/helpers/chrome_theme.dart';

/// Records export requests instead of rendering a PDF and opening a picker.
class _RecordingRunner extends PDFExportRunner {
  final exported = <DrawingDocument>[];

  @override
  Future<void> run(
    ExportProgressNotifier progress,
    DrawingDocument document, {
    bool addWatermark = false,
  }) async {
    exported.add(document);
  }
}

void main() {
  late SharedPreferences prefs;
  late _RecordingRunner runner;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    runner = _RecordingRunner();
  });

  Future<ProviderContainer> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioRecordingEnabledProvider.overrideWithValue(false),
          pdfExportRunnerProvider.overrideWithValue(runner),
        ],
        child: MaterialApp(
          theme: chromeTheme(Brightness.light),
          home: Scaffold(
            body: DrawingThemeProvider(
              theme: const DrawingTheme(),
              child: const Align(
                alignment: Alignment.topCenter,
                child: AdaptiveToolbar(documentTitle: 'Notlar'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final toolbar = tester.element(find.byType(AdaptiveToolbar));
    return ProviderScope.containerOf(toolbar);
  }

  testWidgets('More > Dışa Aktar > PDF runs the export', (tester) async {
    final container = await pumpPhone(tester);

    await tester.tap(find.byTooltip('Daha Fazla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dışa Aktar'));
    await tester.pumpAndSettle();

    // The phone sheet offers the same export as the tablet panel.
    expect(find.byType(ExportPanel), findsOneWidget);
    expect(find.text('PDF İçe Aktar'), findsNothing);
    expect(find.text('Resim Olarak Dışa Aktar'), findsNothing);
    expect(find.text('Paylaş'), findsNothing);

    await tester.tap(find.text('PDF Olarak Dışa Aktar'));
    await tester.pumpAndSettle();

    expect(runner.exported, [container.read(documentProvider)]);
    expect(find.byType(ExportPanel), findsNothing);
  });
}
