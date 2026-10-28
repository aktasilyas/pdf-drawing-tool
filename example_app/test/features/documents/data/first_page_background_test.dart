import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' show right;
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import '../../../helpers/large_document.dart';
import '../../../helpers/library_fixture.dart';

/// V2 content whose first page has [background]; later pages carry strokes.
Map<String, dynamic> _withFirstBackground(PageBackground background) {
  final doc = buildLargeDocument(pages: 3, strokesPerPage: 2);
  final pages = [
    doc.pages.first.copyWith(background: background),
    ...doc.pages.skip(1),
  ];
  return doc.copyWith(pages: pages).toJson();
}

void main() {
  final pdf = PageBackground.pdfLazy(pageIndex: 2, pdfFilePath: 'pdfs/a.pdf');
  final image = PageBackground.pdf(
    pdfData: Uint8List.fromList([1, 2, 3, 4]),
    pageIndex: 0,
  );

  group('DocumentContentCodec.decodeFirstPageBackground', () {
    const codec = DocumentContentCodec();

    test('returns the first page background of V2 content', () async {
      final json = jsonEncode(_withFirstBackground(pdf));
      final map = await codec.decodeFirstPageBackground(json);
      final bg = PageBackground.fromJson(map!);
      expect(bg.pdfFilePath, 'pdfs/a.pdf');
      expect(bg.pdfPageIndex, 2);
    });

    test('image bytes survive the background isolate path', () async {
      const offloaded = DocumentContentCodec(decodeOffloadLength: 1);
      final json = jsonEncode(_withFirstBackground(image));
      final map = await offloaded.decodeFirstPageBackground(json);
      expect(PageBackground.fromJson(map!).pdfData, [1, 2, 3, 4]);
    });

    test('V1, empty or odd shapes give null', () async {
      final v1 = jsonEncode({'id': 'x', 'title': 't', 'layers': []});
      expect(await codec.decodeFirstPageBackground(v1), isNull);
      expect(
        await codec.decodeFirstPageBackground(
          jsonEncode({'version': 2, 'pages': []}),
        ),
        isNull,
      );
      expect(
        await codec.decodeFirstPageBackground(
          jsonEncode({
            'version': '2',
            'pages': ['x'],
          }),
        ),
        isNull,
      );
      expect(
        await codec.decodeFirstPageBackground(
          jsonEncode({
            'version': 2,
            'pages': [
              {'id': 'p'},
            ],
          }),
        ),
        isNull,
      );
    });

    test('invalid JSON throws', () async {
      await expectLater(
        codec.decodeFirstPageBackground('{not json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DocumentRepository.getFirstPageBackground', () {
    late LibraryFixture fx;

    setUp(() => fx = LibraryFixture());
    tearDown(() => fx.close());

    Future<String> createWith(Map<String, dynamic>? content) async {
      final doc = (await fx.documents.createDocument(
        title: 'PDF',
        templateId: 'blank',
      ))
          .getOrElse(() => throw StateError('create failed'));
      if (content != null) {
        await fx.documents.saveDocumentContent(id: doc.id, content: content);
      }
      return doc.id;
    }

    test('returns the stored first page background', () async {
      final id = await createWith(_withFirstBackground(pdf));
      final result = await fx.documents.getFirstPageBackground(id);
      final bg = result.getOrElse(() => throw StateError('left'));
      expect(bg!.pdfFilePath, 'pdfs/a.pdf');
      expect(bg.pdfPageIndex, 2);
    });

    test('an image page gets its bytes loaded from the stored file', () async {
      final dir = Directory.systemTemp.createTempSync('elya_first_bg_');
      addTearDown(() => dir.deleteSync(recursive: true));
      Directory('${dir.path}/elyanotes_images').createSync();
      File('${dir.path}/elyanotes_images/a.png')
          .writeAsBytesSync([9, 8, 7, 6]);
      final rooted = LibraryFixture(null, PdfPathResolver(dir.path));
      addTearDown(rooted.close);
      final doc = (await rooted.documents
              .createDocument(title: 'Img', templateId: 'blank'))
          .getOrElse(() => throw StateError('create failed'));
      await rooted.documents.saveDocumentContent(
        id: doc.id,
        content: _withFirstBackground(
          PageBackground(
            type: BackgroundType.pdf,
            pdfPageIndex: 1,
            imageFilePath: 'elyanotes_images/a.png',
          ),
        ),
      );

      final result = await rooted.documents.getFirstPageBackground(doc.id);

      final bg = result.getOrElse(() => throw StateError('left'));
      expect(bg!.pdfData, [9, 8, 7, 6]);
      expect(bg.imageFilePath, 'elyanotes_images/a.png');
    });

    test('a missing image file gives a background without bytes', () async {
      final id = await createWith(_withFirstBackground(
        PageBackground(
          type: BackgroundType.pdf,
          pdfPageIndex: 1,
          imageFilePath: 'elyanotes_images/gone.png',
        ),
      ));
      final result = await fx.documents.getFirstPageBackground(id);
      final bg = result.getOrElse(() => throw StateError('left'));
      expect(bg!.pdfData, isNull);
      expect(bg.imageFilePath, 'elyanotes_images/gone.png');
    });

    test('a document without content gives Right(null)', () async {
      final id = await createWith(null);
      expect(await fx.documents.getFirstPageBackground(id), right(null));
    });

    test('corrupt content gives a CacheFailure', () async {
      await fx.db.into(fx.db.documentContents).insert(
            DocumentContentsCompanion.insert(
              documentId: 'broken',
              data: '{not json',
              updatedAt: DateTime.utc(2026),
            ),
          );
      final result = await fx.documents.getFirstPageBackground('broken');
      expect(result.fold((f) => f, (_) => null), isA<CacheFailure>());
    });
  });
}
