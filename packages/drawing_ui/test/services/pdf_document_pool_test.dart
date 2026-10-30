// Page thumbnails share one open PDF document per file (#509).
import 'dart:async';
import 'dart:typed_data';

import 'package:drawing_ui/src/services/pdf_document_pool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_pdf_documents.dart';

void main() {
  late FakePdfDocuments pdfs;

  setUp(() => pdfs = FakePdfDocuments());

  test('rendering N pages of one PDF opens the document once', () async {
    final pool = PdfDocumentPool(opener: pdfs.open);

    for (var page = 1; page <= 5; page++) {
      await pool.renderPage('/a.pdf', page, width: 30, height: 40);
    }

    expect(pdfs.openCount('/a.pdf'), 1);
    expect(pdfs.renders.map((r) => r.page), [1, 2, 3, 4, 5]);
    expect(pdfs.closedPaths, isEmpty, reason: 'kept open for the next cell');
  });

  test('concurrent renders of one PDF open it once and run one at a time',
      () async {
    final pool = PdfDocumentPool(opener: pdfs.open);

    await Future.wait([
      for (var page = 1; page <= 4; page++)
        pool.renderPage('/a.pdf', page, width: 30, height: 40),
    ]);

    expect(pdfs.openCount('/a.pdf'), 1);
    expect(pdfs.renders, hasLength(4));
    expect(pdfs.maxConcurrentRenders, 1);
  });

  test('the least recently used document is closed past maxOpen', () async {
    final pool = PdfDocumentPool(opener: pdfs.open, maxOpen: 2);

    await pool.renderPage('/a.pdf', 1, width: 1, height: 1);
    await pool.renderPage('/b.pdf', 1, width: 1, height: 1);
    await pool.renderPage('/a.pdf', 2, width: 1, height: 1);
    await pool.renderPage('/c.pdf', 1, width: 1, height: 1);
    await pumpEventQueue();

    expect(pdfs.closedPaths, ['/b.pdf']);
    expect(pool.openCount, 2);
  });

  test('close() closes every open document', () async {
    final pool = PdfDocumentPool(opener: pdfs.open);
    await pool.renderPage('/a.pdf', 1, width: 1, height: 1);
    await pool.renderPage('/b.pdf', 1, width: 1, height: 1);

    await pool.close();

    expect(pdfs.closedPaths, unorderedEquals(['/a.pdf', '/b.pdf']));
    expect(pool.openCount, 0);
  });

  test('close() waits for a running render before closing', () async {
    final gate = Completer<void>();
    pdfs.renderGate = gate.future;
    final pool = PdfDocumentPool(opener: pdfs.open);

    final render = pool.renderPage('/a.pdf', 1, width: 1, height: 1);
    await pumpEventQueue();
    final closing = pool.close();
    await pumpEventQueue();
    expect(pdfs.closedPaths, isEmpty);

    gate.complete();
    expect(await render, isNotNull);
    await closing;
    expect(pdfs.closedPaths, ['/a.pdf']);
  });

  test('after close() a render opens and closes its own document', () async {
    final pool = PdfDocumentPool(opener: pdfs.open);
    await pool.close();

    final bytes = await pool.renderPage('/a.pdf', 1, width: 1, height: 1);

    expect(bytes, isNotNull);
    expect(pdfs.closedPaths, ['/a.pdf']);
    expect(pool.openCount, 0);
  });

  test('a missing file renders nothing and is not cached', () async {
    pdfs.missing.add('/gone.pdf');
    final pool = PdfDocumentPool(opener: pdfs.open);

    expect(await pool.renderPage('/gone.pdf', 1, width: 1, height: 1), isNull);
    expect(await pool.renderPage('/gone.pdf', 2, width: 1, height: 1), isNull);

    expect(pdfs.openCount('/gone.pdf'), 2, reason: 'retried, not cached');
    expect(pool.openCount, 0);
  });

  test('a render error is rethrown and the document is not reused', () async {
    pdfs.failRender = true;
    final pool = PdfDocumentPool(opener: pdfs.open);

    await expectLater(
      pool.renderPage('/a.pdf', 1, width: 1, height: 1),
      throwsA(isA<StateError>()),
    );
    await pumpEventQueue();

    expect(pool.openCount, 0);
    expect(pdfs.closedPaths, ['/a.pdf']);
    pdfs.failRender = false;
    expect(await pool.renderPage('/a.pdf', 1, width: 1, height: 1),
        isA<Uint8List>());
    expect(pdfs.openCount('/a.pdf'), 2);
  });
}
