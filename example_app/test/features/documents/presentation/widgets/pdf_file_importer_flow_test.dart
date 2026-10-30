import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/l10n/l10n.dart';
import '../../../../helpers/l10n.dart';

class _MockRepo extends Mock implements DocumentRepository {}

class _Controller extends DocumentsController {
  _Controller(Ref ref, this.created) : super(_MockRepo(), ref);

  final List<int> created;

  @override
  Future<String?> createDocumentWithPages({
    required String title,
    String? folderId,
    required core.DocumentType documentType,
    required List<Map<String, dynamic>> pages,
    required int pageCount,
  }) async {
    created.add(pageCount);
    return 'doc-1';
  }
}

core.Page _page(int n) => core.Page.create(
      index: n - 1,
      background: core.PageBackground.pdfLazy(
        pageIndex: n,
        pdfFilePath: 'pdfs/a.pdf',
      ),
    );

/// A PDF of [total] pages: `all()` fails above [PDFImportService.maxPageCount].
class _FakeService extends Fake implements PDFImportService {
  _FakeService(this.total, this.configs);

  final int total;
  final List<PDFImportConfig> configs;

  @override
  Future<PDFImportServiceResult> importFromFile({
    required String filePath,
    required PDFImportConfig config,
  }) async {
    configs.add(config);
    if (config.pageSelection == PDFPageSelection.all) {
      if (total > PDFImportService.maxPageCount) {
        return PDFImportServiceResult.error(PdfImportFailure(
          PdfImportError.tooManyPages,
          pageCount: total,
          maxPages: PDFImportService.maxPageCount,
        ));
      }
      return PDFImportServiceResult.success(
          [for (var p = 1; p <= total; p++) _page(p)]);
    }
    return PDFImportServiceResult.success(
      [for (var p = config.startPage!; p <= config.endPage!; p++) _page(p)],
    );
  }

  @override
  void dispose() {}
}

void main() {
  late List<int> created;
  late List<PDFImportConfig> configs;

  Future<void> pump(
    WidgetTester tester, {
    required int total,
    ChoosePdfPageRange? choose,
  }) async {
    created = [];
    configs = [];
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => importPdfFile(
              context,
              path: 'a.pdf',
              name: 'a.pdf',
              size: 1000,
              createService: () => _FakeService(total, configs),
              chooseRange: choose,
            ),
            child: const Text('go'),
          ),
        ),
      ),
      GoRoute(
        path: '/editor/:documentId',
        builder: (_, __) => const Scaffold(body: Text('editor')),
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsControllerProvider
              .overrideWith((ref) => _Controller(ref, created)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: testLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('640 pages: chosen first 500 become a 500-page document',
      (tester) async {
    await pump(tester, total: 640, choose: (n, max) async {
      expect([n, max], [640, 500]);
      return const PdfPageRange(1, 500);
    });
    expect(created, [500]);
    expect(find.text('editor'), findsOneWidget);
    expect(configs, hasLength(2));
    expect([configs.last.startPage, configs.last.endPage], [1, 500]);
  });

  testWidgets('cancelling the range creates no document and no error',
      (tester) async {
    await pump(tester, total: 640, choose: (_, __) async => null);
    expect(created, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('editor'), findsNothing);
  });

  testWidgets('the default chooser opens the range sheet', (tester) async {
    await pump(tester, total: 640);
    expect(find.byKey(const ValueKey('pdf-range-first')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.byKey(const ValueKey('pdf-range-cancel')));
    await tester.pumpAndSettle();
    expect(created, isEmpty);
  });

  testWidgets('500 pages or fewer import in one call without a sheet',
      (tester) async {
    var asked = false;
    await pump(tester, total: 500, choose: (_, __) async {
      asked = true;
      return null;
    });
    expect(asked, isFalse);
    expect(configs, hasLength(1));
    expect(created, [500]);
  });
}
