import 'dart:io';
import 'dart:typed_data';

import 'package:drawing_ui/drawing_ui.dart'
    show PDFLoader, PdfShareOutcome, PdfShareService;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:example_app/features/documents/presentation/widgets/library_header_parts.dart';
import 'package:example_app/features/documents/presentation/widgets/pdf_file_importer.dart';

import '../fixtures/pdf_fixtures.dart';
import '../helpers/l10n.dart';
import '../helpers/pump_helpers.dart';

/// Stands in for the OS share sheet: writes what would be shared to a file
/// in the temp directory and reports it as shared.
class RecordingShareService extends PdfShareService {
  RecordingShareService();

  final shared = <File>[];

  @override
  Future<PdfShareOutcome> sharePdf(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'e2e_shared', fileName));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    shared.add(file);
    return PdfShareOutcome.shared;
  }
}

/// PDF import and export flows.
///
/// The system file picker cannot be driven from a test, so [importFixture]
/// hands a fixture file to `importPdfFile`, the same function the picker's
/// result goes to; progress dialog, errors and navigation are the app's own.
class PdfRobot {
  PdfRobot(this.tester);

  final WidgetTester tester;

  /// Imports [fixture] from the library screen, without waiting for the
  /// outcome (callers wait for the editor or an error SnackBar).
  Future<void> importFixture(PdfFixture fixture) async {
    final file = await fixture.writeToTemp();
    final context = tester.element(find.byType(LibraryNewButton).first);
    // Not awaited: the import pumps its own dialog and route.
    importPdfFile(
      context,
      path: file.path,
      name: fixture.fileName,
      size: file.lengthSync(),
    ).ignore();
    await tester.pump();
  }

  /// Waits for an error SnackBar containing [message], then for it to go.
  Future<void> expectError(String message) async {
    final snack = find.textContaining(message);
    await tester.pumpUntilFound(snack);
    await tester.pumpUntilGone(snack, timeout: const Duration(seconds: 15));
  }

  /// Editor: "Dışa Aktar" (toolbar button, or the "Daha Fazla" menu on
  /// phones) > "PDF Paylaş".
  Future<void> shareAsPdf() async {
    final s = tester.drawingStrings.toolbar;
    final button = find.byTooltip(s.export).hitTestable();
    if (button.evaluate().isNotEmpty) {
      await tester.tapAndWait(button);
    } else {
      await tester.tapAndWait(find.byTooltip(s.more).hitTestable());
      final item = find.text(s.export);
      await tester.pumpUntilFound(item);
      await tester.ensureVisible(item.first);
      await tester.pumpFor(const Duration(milliseconds: 300));
      await tester.tapAndWait(item.first.hitTestable());
    }
    await tester.tapAndWait(find.text('PDF Paylaş').hitTestable());
  }

  /// Page count of the PDF file at [file], read with the app's own loader.
  Future<int> pageCount(File file) async {
    final loader = PDFLoader();
    try {
      final doc = await loader.loadFromFile(file.path);
      return await loader.getPageCount(doc);
    } finally {
      loader.dispose();
    }
  }
}
