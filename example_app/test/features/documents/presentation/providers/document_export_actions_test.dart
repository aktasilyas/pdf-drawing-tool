import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/presentation/providers/document_export_actions.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';
import 'package:example_app/features/editor/domain/usecases/load_document_usecase.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';

class MockLoadDocumentUseCase extends Mock implements LoadDocumentUseCase {}

class MockDocumentRepository extends Mock implements DocumentRepository {}

class MockPDFExportRunner extends Mock implements PDFExportRunner {}

void main() {
  const strings = ExportStringsTr();
  late MockLoadDocumentUseCase load;
  late MockPDFExportRunner runner;
  late MockDocumentRepository repo;
  var infoMm = (210.0, 297.0);
  late ProviderContainer container;

  final now = DateTime(2026, 1, 1);
  final document = DrawingDocument.multiPage(
    id: 'doc-1',
    title: 'Notes',
    pages: [
      Page.create(index: 0),
      Page.create(index: 1),
      Page.create(index: 2),
    ],
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(ExportProgressNotifier());
    registerFallbackValue(document);
    registerFallbackValue(strings);
  });

  setUp(() {
    load = MockLoadDocumentUseCase();
    runner = MockPDFExportRunner();
    repo = MockDocumentRepository();
    infoMm = (210.0, 297.0);
    when(() => repo.getDocument('doc-1')).thenAnswer((_) async => Right(
          DocumentInfo(
            id: 'doc-1',
            title: 'Notes',
            templateId: 'blank',
            createdAt: now,
            updatedAt: now,
            pageCount: 3,
            paperWidthMm: infoMm.$1,
            paperHeightMm: infoMm.$2,
          ),
        ));
    when(() => runner.run(
          any(),
          any(),
          strings: any(named: 'strings'),
          share: any(named: 'share'),
          isInfiniteCanvas: any(named: 'isInfiniteCanvas'),
          pageFormat: any(named: 'pageFormat'),
        )).thenAnswer((_) async {});
    container = ProviderContainer(overrides: [
      loadDocumentUseCaseProvider.overrideWithValue(load),
      pdfExportRunnerProvider.overrideWithValue(runner),
      documentRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
  });

  test('loads the document once and exports all its pages', () async {
    when(() => load('doc-1')).thenAnswer((_) async => Right(document));

    final ok = await container
        .read(documentExportActionsProvider)
        .exportAsPdf('doc-1', strings: strings);

    expect(ok, isTrue);
    verify(() => load('doc-1')).called(1);
    final captured = verify(() => runner.run(
          any(),
          captureAny(),
          strings: strings,
          share: true,
          isInfiniteCanvas: false,
          pageFormat: any(named: 'pageFormat'),
        )).captured.single as DrawingDocument;
    expect(captured.pages, hasLength(3));
    expect(container.read(libraryErrorProvider), isNull);
  });

  test('a whiteboard document is exported as an infinite canvas', () async {
    final whiteboard = document.copyWith(documentType: DocumentType.whiteboard);
    when(() => load('doc-1')).thenAnswer((_) async => Right(whiteboard));

    await container
        .read(documentExportActionsProvider)
        .exportAsPdf('doc-1', strings: strings);

    verify(() => runner.run(
          any(),
          any(),
          strings: strings,
          share: true,
          isInfiniteCanvas: true,
          pageFormat: any(named: 'pageFormat'),
        )).called(1);
  });

  test('a failed load reports exportDocument and never exports', () async {
    when(() => load('doc-1'))
        .thenAnswer((_) async => const Left(CacheFailure('boom')));

    final ok = await container
        .read(documentExportActionsProvider)
        .exportAsPdf('doc-1', strings: strings);

    expect(ok, isFalse);
    expect(container.read(libraryErrorProvider)?.action,
        LibraryAction.exportDocument);
    verifyNever(() => runner.run(
          any(),
          any(),
          strings: any(named: 'strings'),
          share: any(named: 'share'),
          isInfiniteCanvas: any(named: 'isInfiniteCanvas'),
          pageFormat: any(named: 'pageFormat'),
        ));
  });

  group('paper size (#611)', () {
    PDFPageFormat? exportedFormat() => verify(() => runner.run(
          any(),
          any(),
          strings: any(named: 'strings'),
          share: any(named: 'share'),
          isInfiniteCanvas: any(named: 'isInfiniteCanvas'),
          pageFormat: captureAny(named: 'pageFormat'),
        )).captured.single as PDFPageFormat?;

    test('fresh container: an A4 notebook exports as A4 (595x842 pt)',
        () async {
      when(() => load('doc-1')).thenAnswer((_) async => Right(document));

      await container
          .read(documentExportActionsProvider)
          .exportAsPdf('doc-1', strings: strings);

      final format = exportedFormat()!;
      expect(format.width, closeTo(595, 0.5));
      expect(format.height, closeTo(842, 0.5));
    });

    test('the editor\'s global A5 format does not leak into the export',
        () async {
      when(() => load('doc-1')).thenAnswer((_) async => Right(document));
      container.read(exportPageFormatProvider.notifier).state =
          PDFPageFormat.a5;

      await container
          .read(documentExportActionsProvider)
          .exportAsPdf('doc-1', strings: strings);

      final format = exportedFormat()!;
      expect(format.width, closeTo(595, 0.5));
      expect(format.height, closeTo(842, 0.5));
    });
  });
}
