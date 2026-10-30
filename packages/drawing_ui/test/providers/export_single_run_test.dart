// Only one export runs at a time (#491): a second export started while one is
// running never calls start(), never reaches the exporter or a save/share
// flow, and leaves the running export's progress and Cancel alone.
import 'dart:async';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart' show Page, PdfPathResolver;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/panels/png_export_action.dart';
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

/// Reports page 1 of [total], then waits for [release] before finishing,
/// honouring a cancel requested meanwhile.
class _HeldExporter extends PDFExporter {
  _HeldExporter(this.total);

  final int total;
  final release = Completer<void>();
  void Function(int current, int total)? onProgress;

  @override
  Future<PDFExportResult> exportPages({
    required List<Page> pages,
    PDFDocumentMetadata? metadata,
    PDFExportOptions options = const PDFExportOptions(),
    void Function(int current, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    this.onProgress = onProgress;
    onProgress?.call(1, total);
    await release.future;
    if (isCancelled?.call() ?? false) return PDFExportResult.cancelled();
    return PDFExportResult.success([1, 2, 3]);
  }
}

/// Records whether the second export reached the exporter at all.
class _CountingExporter extends PDFExporter {
  var calls = 0;

  @override
  Future<PDFExportResult> exportPages({
    required List<Page> pages,
    PDFDocumentMetadata? metadata,
    PDFExportOptions options = const PDFExportOptions(),
    void Function(int current, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    calls++;
    return PDFExportResult.success([1, 2, 3]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pages = [for (var i = 0; i < 3; i++) Page.create(index: i)];

  Future<void> runFirst(
    ExportProgressNotifier progress,
    _HeldExporter exporter,
    _FakeShare share,
  ) {
    return performPagesPDFExport(
      progress,
      strings: const ExportStringsTr(),
      pages: pages,
      title: 'Uzun',
      share: true,
      shareService: share,
      exporter: exporter,
    );
  }

  test('tryBegin refuses a second run until end()', () {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    expect(progress.isBusy, isFalse);
    expect(progress.tryBegin(200), isTrue);
    expect(progress.isBusy, isTrue);
    expect(progress.tryBegin(1), isFalse);
    expect(progress.state.totalPages, 200);

    progress.end();
    expect(progress.isBusy, isFalse);
    expect(progress.tryBegin(1), isTrue);
  });

  test('a PDF export during a running one reaches no exporter or share flow',
      () async {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);
    final held = _HeldExporter(200);
    final share = _FakeShare();
    final first = runFirst(progress, held, share);
    await Future<void>.delayed(Duration.zero);

    final second = _CountingExporter();
    final secondShare = _FakeShare();
    await performPagesPDFExport(
      progress,
      strings: const ExportStringsTr(),
      pages: [pages.first],
      title: 'Sayfa',
      share: true,
      shareService: secondShare,
      exporter: second,
    );

    expect(second.calls, 0);
    expect(secondShare.calls, 0);
    // start() was not called again: the running export's state is intact.
    expect(progress.state.status, ExportProgressStatus.exporting);
    expect(progress.state.totalPages, 200);
    expect(progress.state.currentPage, 1);

    // The running export keeps reporting progress.
    held.onProgress!(50, 200);
    expect(progress.state.currentPage, 50);

    held.release.complete();
    await first;
    expect(share.calls, 1);
    expect(progress.state.status, ExportProgressStatus.completed);
    expect(progress.isBusy, isFalse);
  });

  test('Cancel stops only the running export and blocks a restart until it '
      'has stopped', () async {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);
    final held = _HeldExporter(200);
    final share = _FakeShare();
    final first = runFirst(progress, held, share);
    await Future<void>.delayed(Duration.zero);

    progress.requestCancel();
    expect(progress.state.status, ExportProgressStatus.cancelled);

    // The exporter has not stopped yet: a new export must not reset the
    // cancel flag the running one is about to read.
    final second = _CountingExporter();
    await performPagesPDFExport(
      progress,
      strings: const ExportStringsTr(),
      pages: [pages.first],
      title: 'Sayfa',
      exporter: second,
    );
    expect(second.calls, 0);
    expect(progress.isCancelRequested, isTrue);

    held.release.complete();
    await first;
    expect(share.calls, 0);
    expect(progress.state.status, ExportProgressStatus.cancelled);
    expect(progress.isBusy, isFalse);
  });

  test('a PNG export during a running PDF export renders nothing', () async {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);
    final held = _HeldExporter(200);
    final first = runFirst(progress, held, _FakeShare());
    await Future<void>.delayed(Duration.zero);

    var renders = 0;
    await performPNGExport(
      progress,
      pages.first,
      strings: const ExportStringsTr(),
      title: 'Notlar',
      infiniteCanvas: false,
      render: (
        p, {
        required infiniteCanvas,
        pdfPaths = PdfPathResolver.passthrough,
      }) async {
        renders++;
        throw StateError('must not render');
      },
    );

    expect(renders, 0);
    expect(progress.state.status, ExportProgressStatus.exporting);
    expect(progress.state.totalPages, 200);

    held.release.complete();
    await first;
  });

  test('a failed export releases the run', () async {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);

    await performPNGExport(
      progress,
      pages.first,
      strings: const ExportStringsTr(),
      title: 'Notlar',
      infiniteCanvas: false,
      render: (
        p, {
        required infiniteCanvas,
        pdfPaths = PdfPathResolver.passthrough,
      }) async =>
          throw StateError('boom'),
    );

    expect(progress.state.status, ExportProgressStatus.error);
    expect(progress.isBusy, isFalse);
  });
}
