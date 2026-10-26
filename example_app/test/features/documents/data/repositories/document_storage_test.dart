import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/library_fixture.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('elya_storage_');
    file = File('${dir.path}/library.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Map<String, dynamic> fiftyPages() {
    final rnd = Random(7);
    return {
      'pages': [
        for (var i = 0; i < 50; i++)
          {
            'id': 'page-$i',
            'index': i,
            'layers': [
              {
                'strokes': [
                  for (var s = 0; s < 5; s++)
                    {
                      'id': 'stroke-$i-$s',
                      'points': [
                        for (var p = 0; p < 20; p++)
                          {'x': rnd.nextDouble(), 'y': rnd.nextDouble()},
                      ],
                    },
                ],
              },
            ],
          },
      ],
    };
  }

  test('50 pages survive closing and reopening the database', () async {
    final content = fiftyPages();
    var fx = LibraryFixture(NativeDatabase(file));
    final doc = (await fx.documents.createDocument(
      title: 'Big',
      templateId: 'blank',
    ))
        .getOrElse(() => throw StateError('create failed'));
    final saved = await fx.documents.saveDocumentContent(
      id: doc.id,
      content: content,
      pageCount: 50,
      title: 'Big notebook',
    );
    expect(saved.isRight(), isTrue);
    await fx.close();

    fx = LibraryFixture(NativeDatabase(file));
    addTearDown(fx.close);
    final reloaded = (await fx.documents.getDocument(doc.id))
        .getOrElse(() => throw StateError('missing'));
    expect(reloaded.title, 'Big notebook');
    expect(reloaded.pageCount, 50);
    final back =
        (await fx.documents.getDocumentContent(doc.id)).getOrElse(() => null);
    expect(back, content);
    expect((back!['pages'] as List), hasLength(50));
  });

  test('a failed metadata update rolls the content write back', () async {
    final fx = LibraryFixture(NativeDatabase(file));
    addTearDown(fx.close);
    // No document row exists, so the metadata step fails after the content
    // insert; the content must not remain.
    final r = await fx.documents.saveDocumentContent(
      id: 'ghost',
      content: fiftyPages(),
      pageCount: 50,
    );
    expect(r.isLeft(), isTrue);
    expect(await fx.documentDs.hasDocumentContent('ghost'), isFalse);
  });

  test('content write is undone when the metadata update is rejected',
      () async {
    final fx = LibraryFixture(NativeDatabase(file));
    addTearDown(fx.close);
    final doc = (await fx.documents.createDocument(
      title: 'T',
      templateId: 'blank',
    ))
        .getOrElse(() => throw StateError('create failed'));
    await fx.documents.saveDocumentContent(id: doc.id, content: {'pages': []});
    await fx.db.customStatement(
      'CREATE TRIGGER no_meta BEFORE UPDATE ON documents '
      "BEGIN SELECT RAISE(ABORT, 'rejected'); END",
    );

    final r = await fx.documents.saveDocumentContent(
      id: doc.id,
      content: fiftyPages(),
      pageCount: 50,
    );
    expect(r.isLeft(), isTrue);
    expect(await fx.documentDs.getDocumentContent(doc.id), {'pages': []});
    expect((await fx.documentDs.getDocument(doc.id)).pageCount, 1);
  });
}
