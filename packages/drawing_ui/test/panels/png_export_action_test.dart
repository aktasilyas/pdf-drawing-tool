import 'package:drawing_core/drawing_core.dart' show Page, PdfPathResolver;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/png_export_action.dart';
import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders the given page off-screen and reports a render failure',
      () async {
    final progress = ExportProgressNotifier();
    final page = Page.create(index: 0);
    Page? rendered;
    bool? infinite;
    await performPNGExport(
      progress,
      page,
      title: 'Notlar',
      infiniteCanvas: true,
      render: (
        p, {
        required infiniteCanvas,
        pdfPaths = PdfPathResolver.passthrough,
      }) async {
        rendered = p;
        infinite = infiniteCanvas;
        throw StateError('boom');
      },
    );
    expect(rendered, same(page));
    expect(infinite, isTrue);
    expect(progress.state.status, ExportProgressStatus.error);
    expect(progress.state.errorMessage, exportFailedMessage);
  });
}
