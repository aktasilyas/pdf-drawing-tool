// Cancel during a PDF export always cancels it (#490): also after the last
// page is drawn, and never opens the share sheet or the save dialog.
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart' show Page;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeShare extends PdfShareService {
  var calls = 0;

  @override
  Future<PdfShareOutcome> sharePdf(
    Uint8List bytes, {
    required String fileName,
  }) async {
    calls++;
    return PdfShareOutcome.shared;
  }
}

/// Draws the only page, then the user taps Cancel before the exporter
/// returns: the result is already a success.
class _CancelAfterLastPage extends PDFExporter {
  _CancelAfterLastPage(this.progress);

  final ExportProgressNotifier progress;

  @override
  Future<PDFExportResult> exportPages({
    required List<Page> pages,
    PDFDocumentMetadata? metadata,
    PDFExportOptions options = const PDFExportOptions(),
    void Function(int current, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    onProgress?.call(1, 1);
    progress.requestCancel();
    return PDFExportResult.success([1, 2, 3]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancel after the last onProgress returns cancelled', () async {
    var cancel = false;
    final result = await PDFExporter().exportPages(
      pages: [Page.create(index: 0)],
      onProgress: (current, total) => cancel = true,
      isCancelled: () => cancel,
    );

    expect(result.wasCancelled, isTrue);
    expect(result.pdfBytes, isEmpty);
  });

  test('an uncancelled export still succeeds', () async {
    final result = await PDFExporter().exportPages(
      pages: [Page.create(index: 0)],
      isCancelled: () => false,
    );

    expect(result.isSuccess, isTrue);
    expect(result.pdfBytes, isNotEmpty);
  });

  for (final share in [true, false]) {
    final flow = share ? 'share sheet' : 'save dialog';
    test('cancel during a one-page export opens no $flow', () async {
      final progress = ExportProgressNotifier();
      addTearDown(progress.dispose);
      final shareService = _FakeShare();

      // The save path would reach FilePicker, which has no platform
      // implementation in tests and would end in an error state.
      await performPagesPDFExport(
        progress,
        strings: const ExportStringsTr(),
        pages: [Page.create(index: 0)],
        title: 'Notlar',
        share: share,
        shareService: shareService,
        exporter: _CancelAfterLastPage(progress),
      );

      expect(shareService.calls, 0);
      expect(progress.state.status, ExportProgressStatus.cancelled);
    });
  }
}
