// Document content benchmark: longest UI-isolate stall per save/load of a
// 300-page notebook, before vs after #208. Timings are informational.
//
// Run: flutter test test/benchmark (scripts/check.sh runs it alone).
@Tags(['benchmark'])
library;

import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart' show Either;
import 'package:drawing_core/drawing_core.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';

import '../helpers/large_document.dart';
import '../helpers/library_fixture.dart';

/// Longest time the calling isolate's event loop was blocked while [work]
/// ran, sampled with a 1 ms ticker. This is what a UI frame would wait for.
Future<Duration> _longestStall(Future<void> Function() work) async {
  final clock = Stopwatch()..start();
  var last = 0;
  var longest = 0;
  void sample() {
    final now = clock.elapsedMicroseconds;
    if (now - last > longest) longest = now - last;
    last = now;
  }

  final ticker = Timer.periodic(const Duration(milliseconds: 1), (_) {
    sample();
  });
  await work();
  sample();
  ticker.cancel();
  return Duration(microseconds: longest);
}

String _ms(Duration d) => (d.inMicroseconds / 1000).toStringAsFixed(1);

/// Records UI-isolate stall per save/load of a 300-page notebook, before
/// (main-isolate Drift + inline JSON) and after (background Drift + codec).
/// Prints the numbers for the PR; asserts only correctness, not timing.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('content_bench');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  Future<void> measure(
    String label,
    QueryExecutor Function(File file) open,
    DocumentContentCodec codec,
  ) async {
    final document = buildLargeDocument();
    final content = document.toJson();
    final db = AppDatabase(open(File('${dir.path}/$label.db')));
    final ds = DocumentLocalDatasourceImpl(db, codec: codec);
    try {
      // Warm up: open the database and spawn paths once.
      await ds.saveDocumentContent('warmup', {'pages': <Object>[]});

      final save = await _longestStall(
        () => ds.saveDocumentContent(document.id, content),
      );
      Map<String, dynamic>? loaded;
      final load = await _longestStall(() async {
        loaded = await ds.getDocumentContent(document.id);
      });
      expect(loaded, equals(content));

      final toJson = Stopwatch()..start();
      document.toJson();
      toJson.stop();

      debugPrint('[content-bench] $label: longest UI-isolate stall '
          'save ${_ms(save)} ms, load ${_ms(load)} ms '
          '(toJson in the use case, unchanged: ${_ms(toJson.elapsed)} ms)');
    } finally {
      await db.close();
    }
  }

  test('300-page save/load: before vs after', () async {
    await measure(
      'before',
      (file) => NativeDatabase(file),
      const DocumentContentCodec.inline(),
    );
    await measure(
      'after',
      (file) => NativeDatabase.createInBackground(file),
      const DocumentContentCodec(),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('300-page use cases (model <-> JSON <-> DB): stall stays small',
      () async {
    final fx = LibraryFixture(
      NativeDatabase.createInBackground(File('${dir.path}/use_case.db')),
    );
    try {
      final created = (await fx.documents.createDocument(
        title: 'Büyük defter',
        templateId: 'blank',
      ))
          .getOrElse(() => throw StateError('create failed'));
      final document = buildLargeDocument().copyWith(id: created.id);
      final save = SaveDocumentUseCase(fx.documents);
      final load = LoadDocumentUseCase(fx.documents);

      // Warm up the database and isolate spawn paths.
      // A medium document also warms the JIT for the slicing code paths.
      final warm = buildLargeDocument(pages: 30).copyWith(id: created.id);
      await save(warm);
      await load(created.id);

      late final Either<Failure, void> saved;
      final saveStall = await _longestStall(() async {
        saved = await save(document);
      });
      expect(saved.isRight(), isTrue);

      late final Either<Failure, DrawingDocument> loaded;
      final loadStall = await _longestStall(() async {
        loaded = await load(created.id);
      });
      final restored = loaded.getOrElse(() => throw StateError('load failed'));
      expect(restored.pageCount, document.pageCount);

      debugPrint('[content-bench] use case: longest UI-isolate stall '
          'save ${_ms(saveStall)} ms, load ${_ms(loadStall)} ms '
          '(budget 50 ms)');
      // Timing varies a lot between machines (JIT, shared runners), so the
      // test only guards against a return to the single-shot path (seconds
      // on a slow machine); the 50 ms goal is tracked via the notice.
      expect(saveStall, lessThan(const Duration(milliseconds: 250)));
      expect(loadStall, lessThan(const Duration(milliseconds: 250)));
    } finally {
      await fx.close();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
