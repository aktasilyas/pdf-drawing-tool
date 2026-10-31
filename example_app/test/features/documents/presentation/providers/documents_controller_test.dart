import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import 'package:example_app/features/documents/presentation/providers/imported_document_content.dart';

import 'documents_controller_harness.dart';

typedef _BuildContent = Map<String, dynamic> Function(DocumentInfo);

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

    /// Stubs the one-transaction import; on success the content builder is
    /// run against [testDocument] and its result kept in [savedContent].
    void stubImport(Future<Either<Failure, DocumentInfo>> Function() answer) {
      when(() => h.repo.createDocumentWithContent(
            title: any(named: 'title'),
            templateId: any(named: 'templateId'),
            folderId: any(named: 'folderId'),
            paperColor: any(named: 'paperColor'),
            isPortrait: any(named: 'isPortrait'),
            documentType: any(named: 'documentType'),
            paperWidthMm: any(named: 'paperWidthMm'),
            paperHeightMm: any(named: 'paperHeightMm'),
            pageCount: any(named: 'pageCount'),
            buildContent: any(named: 'buildContent'),
          )).thenAnswer((invocation) async {
        final build = invocation.namedArguments[#buildContent] as _BuildContent;
        final result = await answer();
        result.fold((_) {}, (doc) => savedContent = build(doc));
        return result;
      });
    }

    test('imports row and V2 content in one call, refreshing every list',
        () async {
      stubImport(() async => Right(testDocument));
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
      verify(() => h.repo.createDocumentWithContent(
            title: 'Imported',
            templateId: 'blank',
            folderId: any(named: 'folderId'),
            paperColor: any(named: 'paperColor'),
            isPortrait: any(named: 'isPortrait'),
            documentType: DocumentType.pdf,
            paperWidthMm: any(named: 'paperWidthMm'),
            paperHeightMm: any(named: 'paperHeightMm'),
            pageCount: 1,
            buildContent: any(named: 'buildContent'),
          )).called(1);
    });

    test('landscape pages create a landscape row with matching paper mm',
        () async {
      stubImport(() async => Right(testDocument));
      await h.controller.createDocumentWithPages(
        title: 'Slides',
        documentType: DocumentType.pdf,
        pages: [
          {
            'id': 'p1',
            'index': 0,
            'size': {'width': 960.0, 'height': 540.0},
          },
        ],
        pageCount: 1,
      );
      final call = verify(() => h.repo.createDocumentWithContent(
            title: any(named: 'title'),
            templateId: any(named: 'templateId'),
            folderId: any(named: 'folderId'),
            paperColor: any(named: 'paperColor'),
            isPortrait: captureAny(named: 'isPortrait'),
            documentType: any(named: 'documentType'),
            paperWidthMm: captureAny(named: 'paperWidthMm'),
            paperHeightMm: captureAny(named: 'paperHeightMm'),
            pageCount: any(named: 'pageCount'),
            buildContent: any(named: 'buildContent'),
          ));
      expect(call.captured[0], false);
      expect(call.captured[1], closeTo(540 * 25.4 / 72, 0.01));
      expect(call.captured[2], closeTo(960 * 25.4 / 72, 0.01));
    });

    test('pages without size keep A4 portrait', () {
      final paper = importedPaperFromPages(pages);
      expect(paper, (isPortrait: true, widthMm: 210.0, heightMm: 297.0));
    });

    test('returns null and exposes the failure when the import fails',
        () async {
      stubImport(() async => const Left(failure));
      final rebuilt = await h.rebuiltBy(() async {
        expect(await run(), isNull);
      });
      expect(rebuilt, isEmpty);
      expect(h.state.error, failure);
      // The transaction already dropped the row; no cleanup delete is needed.
      verifyNever(() => h.repo.permanentlyDelete(any()));
    });

    test('returns null when the repository throws', () async {
      stubImport(() async => throw StateError('disk'));
      expect(await run(), isNull);
      expect(h.state.error, isA<StateError>());
      verifyNever(() => h.repo.permanentlyDelete(any()));
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
