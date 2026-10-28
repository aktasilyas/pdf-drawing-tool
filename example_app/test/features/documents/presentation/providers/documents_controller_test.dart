import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import 'documents_controller_harness.dart';

void main() {
  setUpAll(registerDocumentsFallbacks);

  late DocumentsHarness h;
  Map<String, dynamic>? savedContent;

  setUp(() => h = DocumentsHarness());
  tearDown(() => h.dispose());

  void stubCreate(Future<Either<Failure, DocumentInfo>> Function() answer) {
    when(() => h.repo.createDocument(
          title: any(named: 'title'),
          templateId: any(named: 'templateId'),
          folderId: any(named: 'folderId'),
          paperColor: any(named: 'paperColor'),
          isPortrait: any(named: 'isPortrait'),
          documentType: any(named: 'documentType'),
          coverId: any(named: 'coverId'),
          hasCover: any(named: 'hasCover'),
          paperWidthMm: any(named: 'paperWidthMm'),
          paperHeightMm: any(named: 'paperHeightMm'),
        )).thenAnswer((_) => answer());
  }

  void stubSave(Future<Either<Failure, void>> Function() answer) {
    when(() => h.repo.saveDocumentContent(
          id: any(named: 'id'),
          content: any(named: 'content'),
          pageCount: any(named: 'pageCount'),
          updatedAt: any(named: 'updatedAt'),
          coverId: any(named: 'coverId'),
          updateCover: any(named: 'updateCover'),
        )).thenAnswer((invocation) {
      savedContent =
          invocation.namedArguments[#content] as Map<String, dynamic>;
      return answer();
    });
  }

  group('createDocument', () {
    test('returns the new id and refreshes every list', () async {
      stubCreate(() async => Right(testDocument));
      String? id;
      final rebuilt = await h.rebuiltBy(() async {
        id = await h.controller.createDocument(
          title: 'Notes',
          templateId: 'blank',
        );
      });
      expect(id, 'doc-1');
      expect(rebuilt, allLists);
      expect(h.state, const AsyncData<void>(null));
    });

    test('returns null and exposes the failure', () async {
      stubCreate(() async => const Left(failure));
      String? id = 'x';
      final rebuilt = await h.rebuiltBy(() async {
        id = await h.controller.createDocument(
          title: 'Notes',
          templateId: 'blank',
        );
      });
      expect(id, isNull);
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
    });
  });

  group('createDocumentWithPages', () {
    final pages = [
      {'id': 'p1', 'index': 0},
    ];

    Future<String?> run() => h.controller.createDocumentWithPages(
          title: 'Imported',
          documentType: DocumentType.pdf,
          pages: pages,
          pageCount: 1,
        );

    test('saves V2 content and refreshes every list', () async {
      stubCreate(() async => Right(testDocument));
      stubSave(() async => const Right(null));
      String? id;
      final rebuilt = await h.rebuiltBy(() async {
        id = await run();
      });
      expect(id, 'doc-1');
      expect(rebuilt, allLists);
      final content = savedContent!;
      expect(content['version'], 2);
      expect(content['id'], 'doc-1');
      expect(content['pages'], pages);
      expect(content['documentType'], DocumentType.pdf.name);
    });

    test('returns null when creating fails', () async {
      stubCreate(() async => const Left(failure));
      final rebuilt = await h.rebuiltBy(() async {
        expect(await run(), isNull);
      });
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
      verifyNever(() => h.repo.saveDocumentContent(
            id: any(named: 'id'),
            content: any(named: 'content'),
            pageCount: any(named: 'pageCount'),
          ));
    });

    test('returns null when saving content fails', () async {
      stubCreate(() async => Right(testDocument));
      stubSave(() async => const Left(failure));
      when(() => h.repo.permanentlyDelete(any()))
          .thenAnswer((_) async => const Right(null));
      final rebuilt = await h.rebuiltBy(() async {
        expect(await run(), isNull);
      });
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
      verify(() => h.repo.permanentlyDelete('doc-1')).called(1);
    });

    test('deletes the document row when saving content throws', () async {
      stubCreate(() async => Right(testDocument));
      stubSave(() async => throw StateError('disk full'));
      when(() => h.repo.permanentlyDelete(any()))
          .thenAnswer((_) async => const Right(null));
      expect(await run(), isNull);
      verify(() => h.repo.permanentlyDelete('doc-1')).called(1);
    });

    test('returns null when the repository throws', () async {
      stubCreate(() async => throw StateError('disk'));
      expect(await run(), isNull);
      expect(h.state.error, isA<StateError>());
    });
  });

  group('moveDocument', () {
    test('success refreshes every list', () async {
      when(() => h.repo.moveDocument('doc-1', 'f1'))
          .thenAnswer((_) async => const Right(null));
      late bool ok;
      final rebuilt = await h.rebuiltBy(() async {
        ok = await h.controller.moveDocument('doc-1', 'f1');
      });
      expect(ok, isTrue);
      expect(rebuilt, allLists);
      expect(h.state, const AsyncData<void>(null));
    });

    test('failure returns false', () async {
      when(() => h.repo.moveDocument('doc-1', null))
          .thenAnswer((_) async => const Left(failure));
      late bool ok;
      final rebuilt = await h.rebuiltBy(() async {
        ok = await h.controller.moveDocument('doc-1', null);
      });
      expect(ok, isFalse);
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
    });
  });
}
