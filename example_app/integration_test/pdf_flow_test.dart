import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:drawing_ui/drawing_ui.dart'
    show documentProvider, pdfShareServiceProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'fixtures/pdf_fixtures.dart';
import 'helpers/app_harness.dart';
import 'helpers/l10n.dart';
import 'helpers/pump_helpers.dart';
import 'robots/editor_robot.dart';
import 'robots/library_robot.dart';
import 'robots/pdf_robot.dart';

void main() {
  initE2E();

  testWidgets(
    'pdf: broken and locked files are refused, a multi-page PDF imports '
    'with a container-relative path, is annotated and exported via share',
    (tester) async {
      final share = RecordingShareService();
      await launchApp(
        tester,
        overrides: [pdfShareServiceProvider.overrideWithValue(share)],
      );
      final library = LibraryRobot(tester);
      final editor = EditorRobot(tester);
      final pdf = PdfRobot(tester);
      await library.waitForLibrary();
      library.expectEmptyState();

      // Corrupted and password-protected files: friendly error (#186),
      // nothing added to the library.
      await pdf.importFixture(PdfFixture.corrupt);
      final s = tester.drawingStrings.errors;
      await pdf.expectAnyError([s.pdfOpenFailed, s.pdfPagesUnreadable]);
      library.expectEmptyState();

      await pdf.importFixture(PdfFixture.locked);
      await pdf.expectError(s.pdfPasswordProtected);
      library.expectEmptyState();

      // A normal 3-page PDF opens in the editor with one page per PDF page.
      const plain = PdfFixture.plain;
      await pdf.importFixture(plain);
      await editor.waitForEditor();
      await tester.pumpUntilTrue(
        () => editor.read(documentProvider).pages.length == plain.pageCount,
        reason: 'imported pages: ${editor.read(documentProvider).pages.length}',
        timeout: const Duration(seconds: 20),
      );

      // Stored PDF path is relative to the app container (#209/#220).
      final paths = {
        for (final page in editor.read(documentProvider).pages)
          page.background.pdfFilePath,
      };
      expect(paths, hasLength(1), reason: 'one source file: $paths');
      final stored = paths.single;
      expect(stored, isNotNull);
      expect(p.isAbsolute(stored!), isFalse, reason: stored);
      expect(stored, startsWith('${PdfPathResolver.pdfDir}/'));

      // Annotate the first page.
      await editor.drawStroke(0.3);
      expect(editor.strokeIds(), hasLength(1));

      // Export through "Share PDF"; the stubbed share sheet keeps the file.
      await pdf.shareAsPdf();
      await tester.pumpUntilTrue(
        () => share.shared.isNotEmpty,
        reason: 'export did not reach the share sheet',
        timeout: const Duration(seconds: 60),
      );
      final exported = share.shared.single;
      expect(exported.existsSync(), isTrue);
      expect(exported.lengthSync(), greaterThan(0));
      expect(await pdf.pageCount(exported), plain.pageCount);

      // Back in the library the imported document is listed.
      await editor.goHome();
      await library.waitForLibrary();
      await library.waitListed(p.basenameWithoutExtension(plain.fileName));
    },
  );
}
