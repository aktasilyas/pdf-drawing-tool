import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart'
    show BackgroundType, Page, PageBackground, PageSize;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

class _MockCounter extends Mock implements PdfPageCounter {}

class _MockFiles extends Mock implements PdfSourceFiles {}

void main() {
  const stored = 'pdfs/a.pdf';
  const picked = '/picked/b.pdf';
  late _MockCounter counter;
  late _MockFiles files;
  late RelinkPdfSourceUseCase useCase;

  setUp(() {
    counter = _MockCounter();
    files = _MockFiles();
    useCase = RelinkPdfSourceUseCase(counter, files);
    when(() => files.exists(stored)).thenAnswer((_) async => false);
    when(() => files.install(picked, stored))
        .thenAnswer((_) async => const Right(unit));
  });

  Future<Either<Failure, Unit>> run({int requiredPages = 5}) => useCase(
        storedPath: stored,
        pickedPath: picked,
        requiredPages: requiredPages,
      );

  test('installs the picked file at the stored path', () async {
    when(() => counter.pageCount(picked))
        .thenAnswer((_) async => const Right(5));

    expect(await run(), const Right<Failure, Unit>(unit));

    verify(() => files.install(picked, stored)).called(1);
  });

  test('fewer pages than required gives pageCountMismatch, writes nothing',
      () async {
    when(() => counter.pageCount(picked))
        .thenAnswer((_) async => const Right(3));

    expect(
      await run(),
      const Left<Failure, Unit>(
        PdfRelinkFailure(
          PdfRelinkError.pageCountMismatch,
          found: 3,
          required: 5,
        ),
      ),
    );

    verifyNever(() => files.install(any(), any()));
  });

  test('counter failure is propagated, writes nothing', () async {
    when(() => counter.pageCount(picked)).thenAnswer(
      (_) async =>
          const Left(PdfRelinkFailure(PdfRelinkError.passwordProtected)),
    );

    expect(
      await run(),
      const Left<Failure, Unit>(
        PdfRelinkFailure(PdfRelinkError.passwordProtected),
      ),
    );

    verifyNever(() => files.install(any(), any()));
  });

  test('an existing target is never touched', () async {
    when(() => files.exists(stored)).thenAnswer((_) async => true);

    expect(
      await run(),
      const Left<Failure, Unit>(PdfRelinkFailure(PdfRelinkError.targetExists)),
    );

    verifyNever(() => counter.pageCount(any()));
    verifyNever(() => files.install(any(), any()));
  });

  test('install failure is returned as is', () async {
    when(() => counter.pageCount(picked))
        .thenAnswer((_) async => const Right(5));
    when(() => files.install(picked, stored)).thenAnswer(
      (_) async => const Left(PdfRelinkFailure(PdfRelinkError.storageFull)),
    );

    expect(
      await run(),
      const Left<Failure, Unit>(PdfRelinkFailure(PdfRelinkError.storageFull)),
    );
  });

  group('requiredPagesFor', () {
    final now = DateTime(2026, 7, 2);
    Page page(PageBackground background) => Page(
          id: 'p${background.hashCode}',
          index: 0,
          size: PageSize.a4Portrait,
          background: background,
          createdAt: now,
          updatedAt: now,
        );

    test('is the highest 1-based index of pages using the path', () {
      final pages = [
        page(PageBackground.pdfLazy(pageIndex: 2, pdfFilePath: stored)),
        page(PageBackground.pdfLazy(pageIndex: 7, pdfFilePath: stored)),
        page(
          PageBackground.pdfLazy(pageIndex: 9, pdfFilePath: 'pdfs/other.pdf'),
        ),
      ];

      expect(RelinkPdfSourceUseCase.requiredPagesFor(pages, stored), 7);
    });

    test('ignores pages without an index and returns 0 for none', () {
      final pages = [
        page(
          const PageBackground(
            type: BackgroundType.pdf,
            pdfFilePath: stored,
          ),
        ),
        page(PageBackground.blank),
      ];

      expect(RelinkPdfSourceUseCase.requiredPagesFor(pages, stored), 0);
      expect(RelinkPdfSourceUseCase.requiredPagesFor(const [], stored), 0);
    });
  });
}
