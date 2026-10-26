// Document content benchmark: longest UI-isolate stall per save/load of a
// 300-page notebook, before vs after #208. Timings are informational.
//
// Run: flutter test test/benchmark (scripts/check.sh runs it alone).
@Tags(['benchmark'])
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import '../helpers/large_document.dart';

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
}
