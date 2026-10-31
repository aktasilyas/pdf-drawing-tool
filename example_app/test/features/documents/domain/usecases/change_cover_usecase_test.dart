import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

const _id = 'doc-1';
final _old = CoverRegistry.byId('linen_sage')!;
final _new = CoverRegistry.byId('linen_sand')!;

DocumentInfo _info({bool hasCover = true}) => DocumentInfo(
      id: _id,
      title: 'Notebook',
      templateId: 'blank',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      coverId: _old.id,
      hasCover: hasCover,
    );

Stroke _stroke() =>
    Stroke.create(style: StrokeStyle.pen()).addPoint(DrawingPoint(x: 1, y: 1));

Page _coverPage() {
  final page = Page.createCover(
    index: 0,
    background: PageBackground(
      type: BackgroundType.cover,
      coverId: _old.id,
      color: _old.primaryColor,
    ),
  );
  final layer = page.layers.first.addStroke(_stroke());
  return page.copyWith(layers: [layer]);
}

Page _contentPage(int index) {
  final page = Page.create(index: index);
  return page.copyWith(
    layers: [page.layers.first.addStroke(_stroke())],
  );
}

DrawingDocument _doc(List<Page> pages) => DrawingDocument.multiPage(
      id: _id,
      title: 'Notebook',
      pages: pages,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  late MockDocumentRepository repo;
  late ChangeCoverUseCase useCase;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    repo = MockDocumentRepository();
    useCase = ChangeCoverUseCase(repo);
    when(() => repo.getDocument(_id)).thenAnswer((_) async => Right(_info()));
    when(() => repo.updateCover(any(), any()))
        .thenAnswer((_) async => const Right(null));
    when(
      () => repo.saveDocumentContent(
        id: any(named: 'id'),
        content: any(named: 'content'),
        pageCount: any(named: 'pageCount'),
        updatedAt: any(named: 'updatedAt'),
        coverId: any(named: 'coverId'),
        updateCover: any(named: 'updateCover'),
        title: any(named: 'title'),
      ),
    ).thenAnswer((_) async => const Right(null));
  });

  void stubStored(DrawingDocument? doc) {
    when(() => repo.getDrawingDocument(_id))
        .thenAnswer((_) async => Right(doc));
  }

  Map<String, dynamic> verifySaved({required int pageCount}) {
    final captured = verify(
      () => repo.saveDocumentContent(
        id: _id,
        content: captureAny(named: 'content'),
        pageCount: pageCount,
        updatedAt: any(named: 'updatedAt'),
        coverId: _new.id,
        updateCover: true,
        title: any(named: 'title'),
      ),
    ).captured;
    return captured.single as Map<String, dynamic>;
  }

  void verifyNoWrites() {
    verifyNever(() => repo.updateCover(any(), any()));
    verifyNever(
      () => repo.saveDocumentContent(
        id: any(named: 'id'),
        content: any(named: 'content'),
        pageCount: any(named: 'pageCount'),
        updatedAt: any(named: 'updatedAt'),
        coverId: any(named: 'coverId'),
        updateCover: any(named: 'updateCover'),
        title: any(named: 'title'),
      ),
    );
  }

  group('ChangeCoverUseCase', () {
    test('swaps the cover background and keeps the ink on the cover page',
        () async {
      stubStored(_doc([_coverPage(), _contentPage(1)]));

      final result = await useCase(_id, _new.id);

      expect(result.isRight(), true);
      final saved = DrawingDocument.fromJson(verifySaved(pageCount: 2));
      final cover = saved.pages[0];
      expect(cover.isCover, true);
      expect(cover.background.type, BackgroundType.cover);
      expect(cover.background.coverId, _new.id);
      expect(cover.background.color, _new.primaryColor);
      expect(cover.strokeCount, 1);
    });

    test('leaves the other pages unchanged', () async {
      final original = _doc([_coverPage(), _contentPage(1), _contentPage(2)]);
      stubStored(original);

      await useCase(_id, _new.id);

      final saved = DrawingDocument.fromJson(verifySaved(pageCount: 3));
      for (final i in [1, 2]) {
        expect(saved.pages[i].toJson(), original.pages[i].toJson());
      }
    });

    test('never opened: only the row is updated', () async {
      stubStored(null);

      final result = await useCase(_id, _new.id);

      expect(result.isRight(), true);
      verify(() => repo.updateCover(_id, _new.id)).called(1);
      verifyNever(
        () => repo.saveDocumentContent(
          id: any(named: 'id'),
          content: any(named: 'content'),
          pageCount: any(named: 'pageCount'),
          updatedAt: any(named: 'updatedAt'),
          coverId: any(named: 'coverId'),
          updateCover: any(named: 'updateCover'),
          title: any(named: 'title'),
        ),
      );
    });

    test('no cover page yet: inserts one at index 0', () async {
      stubStored(_doc([_contentPage(0)]));

      final result = await useCase(_id, _new.id);

      expect(result.isRight(), true);
      final saved = DrawingDocument.fromJson(verifySaved(pageCount: 2));
      expect(saved.pages[0].isCover, true);
      expect(saved.pages[0].background.coverId, _new.id);
      expect(saved.pages[1].strokeCount, 1);
    });

    test('unknown cover id fails validation without writing', () async {
      final result = await useCase(_id, 'no_such_cover');

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );
      verifyNever(() => repo.getDocument(any()));
      verifyNoWrites();
    });

    test('a notebook without cover fails validation without writing', () async {
      when(() => repo.getDocument(_id))
          .thenAnswer((_) async => Right(_info(hasCover: false)));

      final result = await useCase(_id, _new.id);

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Should fail'),
      );
      verifyNoWrites();
    });

    test('propagates a repository failure', () async {
      const failure = CacheFailure('boom');
      stubStored(_doc([_coverPage(), _contentPage(1)]));
      when(
        () => repo.saveDocumentContent(
          id: any(named: 'id'),
          content: any(named: 'content'),
          pageCount: any(named: 'pageCount'),
          updatedAt: any(named: 'updatedAt'),
          coverId: any(named: 'coverId'),
          updateCover: any(named: 'updateCover'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(_id, _new.id);

      expect(result, const Left<Failure, void>(failure));
    });

    test('propagates a failure to read the stored content', () async {
      const failure = CacheFailure('read failed');
      when(() => repo.getDrawingDocument(_id))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(_id, _new.id);

      expect(result, const Left<Failure, void>(failure));
      verifyNoWrites();
    });
  });
}
