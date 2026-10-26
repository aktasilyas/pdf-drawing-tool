import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart' show Page;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/services/pdf_share_service.dart';
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

  Future<ExportProgressNotifier> run(_FakeShare share) async {
    final progress = ExportProgressNotifier();
    await performPagesPDFExport(
      progress,
      pages: [Page.create(index: 0)],
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

  test('dismissing the share sheet is not an error', () async {
    final progress = await run(_FakeShare(PdfShareOutcome.dismissed));

    expect(progress.state.status, ExportProgressStatus.idle);
  });
}
