import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart' show ImageElement, Page;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeShare extends PdfShareService {
  _FakeShare(this.outcome);

  final PdfShareOutcome outcome;
  final names = <String>[];

  @override
  Future<PdfShareOutcome> sharePdf(
    Uint8List bytes, {
    required String fileName,
  }) async {
    expect(bytes, isNotEmpty);
    names.add(fileName);
    return outcome;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ExportProgressNotifier> run(_FakeShare share, {Page? page}) async {
    final progress = ExportProgressNotifier();
    addTearDown(progress.dispose);
    await performPagesPDFExport(
      progress,
      strings: const ExportStringsTr(),
      pages: [page ?? Page.create(index: 0)],
      title: 'Notlar',
      share: true,
      shareService: share,
    );
    return progress;
  }

  test('share hands the PDF to the share service and completes', () async {
    final share = _FakeShare(PdfShareOutcome.shared);
    final progress = await run(share);

    expect(share.names.single, matches(RegExp(r'^Notlar_\d{8}_\d{4}\.pdf$')));
    expect(progress.state.status, ExportProgressStatus.completed);
  });

  test('pages with unreadable images reach the saved notice', () async {
    final blank = Page.create(index: 0);
    final image = ImageElement.create(
      filePath: '/nonexistent/gone.png',
      x: 0,
      y: 0,
      width: 9,
      height: 9,
    );
    final page = blank.copyWith(
      layers: [
        blank.layers.first.copyWith(images: [image]),
      ],
    );
    final progress = await run(_FakeShare(PdfShareOutcome.shared), page: page);

    expect(progress.state.status, ExportProgressStatus.completed);
    expect(progress.state.pagesMissingImages, 1);
    expect(progress.state.pagesMissingBackground, 0);
  });

  test('dismissing the share sheet is not an error', () async {
    final progress = await run(_FakeShare(PdfShareOutcome.dismissed));

    expect(progress.state.status, ExportProgressStatus.idle);
  });
}
