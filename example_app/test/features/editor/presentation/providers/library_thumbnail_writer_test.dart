import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/widgets.dart' show TextScaler;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/presentation/widgets/library_grid_metrics.dart';
import 'package:example_app/features/editor/presentation/providers/library_thumbnail_writer.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

class _Render {
  _Render(this.page, this.width, this.height, this.done);
  final Page page;
  final int width;
  final int height;
  final Completer<Uint8List?> done;
}

void main() {
  late _MockDocumentRepository repo;
  late List<_Render> renders;
  late int written;
  final png = Uint8List.fromList([1, 2, 3]);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repo = _MockDocumentRepository();
    renders = [];
    written = 0;
    when(() => repo.saveThumbnail(any(), any()))
        .thenAnswer((_) async => const Right('thumb.png'));
  });

  LibraryThumbnailWriter writer({bool enabled = true}) =>
      LibraryThumbnailWriter(
        enabled: enabled,
        repository: () => repo,
        render: (page, width, height) {
          final done = Completer<Uint8List?>();
          renders.add(_Render(page, width, height, done));
          return done.future;
        },
        onWritten: () => written++,
      );

  DrawingDocument docWith(List<Page> pages) {
    final base = DrawingDocument.emptyMultiPage('A');
    return base.copyWith(id: 'doc_a', pages: pages);
  }

  Page page(int index, {bool isCover = false}) =>
      Page.create(index: index, isCover: isCover);

  test('an edit on another page does not render or save (AC4)', () async {
    final p0 = page(0);
    final before = docWith([p0]);
    final after = docWith([p0, page(1)]);
    final w = writer()..baseline(before);

    w.request(after);
    await w.idle;

    expect(renders, isEmpty);
    verifyNever(() => repo.saveThumbnail(any(), any()));
    expect(written, 0);
  });

  test('a new first page is rendered at the library size and saved once',
      () async {
    final w = writer()..baseline(docWith([page(0)]));
    final changed = docWith([page(0)]);

    w.request(changed);
    expect(renders, hasLength(1));
    final size = libraryThumbnailPixels(
      changed.pages.first.size.width,
      changed.pages.first.size.height,
    );
    expect(renders.single.width, size.width);
    expect(renders.single.height, size.height);
    expect(renders.single.page, same(changed.pages.first));

    renders.single.done.complete(png);
    await w.idle;

    verify(() => repo.saveThumbnail('doc_a', png)).called(1);
    expect(written, 1);

    // The written page is recorded: the same document is not rewritten.
    w.request(changed);
    await w.idle;
    expect(renders, hasLength(1));
  });

  test('a cover first page is skipped', () async {
    final w = writer();
    w.request(docWith([page(0, isCover: true), page(1)]));
    await w.idle;
    expect(renders, isEmpty);
    verifyNever(() => repo.saveThumbnail(any(), any()));
  });

  test('a render without bytes is not saved', () async {
    final w = writer();
    w.request(docWith([page(0)]));
    renders.single.done.complete(null);
    await w.idle;
    verifyNever(() => repo.saveThumbnail(any(), any()));
    expect(written, 0);
  });

  test('requests during a render coalesce to the newest', () async {
    final w = writer();
    final d1 = docWith([page(0)]);
    final d2 = docWith([page(0)]);
    final d3 = docWith([page(0)]);

    w.request(d1);
    w.request(d2);
    w.request(d3);
    expect(renders, hasLength(1));
    expect(renders.first.page, same(d1.pages.first));

    renders.first.done.complete(png);
    await pumpEventQueue();
    expect(renders, hasLength(2));
    expect(renders.last.page, same(d3.pages.first));

    renders.last.done.complete(png);
    await w.idle;
    verify(() => repo.saveThumbnail('doc_a', png)).called(2);
    expect(written, 2);
  });

  test('a disabled writer does nothing', () async {
    final w = writer(enabled: false);
    w.baseline(docWith([page(0)]));
    w.request(docWith([page(0)]));
    await w.idle;
    expect(renders, isEmpty);
    verifyNever(() => repo.saveThumbnail(any(), any()));
  });

  test('a failing render never throws', () async {
    final w = LibraryThumbnailWriter(
      enabled: true,
      repository: () => repo,
      render: (page, width, height) async => throw StateError('boom'),
    );
    w.request(docWith([page(0)]));
    await w.idle;
    verifyNever(() => repo.saveThumbnail(any(), any()));
  });

  group('libraryThumbnailPixels', () {
    test('keeps the page aspect ratio at 720px wide', () {
      final size = libraryThumbnailPixels(210, 297);
      expect(size.width, 720);
      expect(size.height, (720 * 297 / 210).ceil());
    });

    test('caps the height and defaults an unusable size', () {
      expect(libraryThumbnailPixels(100, 10000).height, 2048);
      expect(libraryThumbnailPixels(0, 0), (width: 720, height: 960));
      expect(libraryThumbnailPixels(-1, 5), (width: 720, height: 960));
    });

    test('is sharp enough for phone and tablet tiles (AC2)', () {
      final width = libraryThumbnailPixels(210, 297).width;
      final phone = LibraryGridMetrics.resolve(
        availableWidth:
            412 - 2 * LibraryGridMetrics.paneHorizontalPadding(true),
        isPhone: true,
        textScaler: TextScaler.noScaling,
      );
      final tablet = LibraryGridMetrics.resolve(
        availableWidth:
            1280 - 2 * LibraryGridMetrics.paneHorizontalPadding(false),
        isPhone: false,
        textScaler: TextScaler.noScaling,
      );
      expect(width, greaterThanOrEqualTo(phone.tileWidth * 3.0));
      expect(width, greaterThanOrEqualTo(tablet.tileWidth * 2.0));
      expect(width, greaterThanOrEqualTo(LibraryGridMetrics.minTileWidth * 3));
    });
  });
}
