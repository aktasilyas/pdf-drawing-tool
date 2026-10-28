import 'dart:async';

import 'package:drawing_ui/src/services/pdf_render_queue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets the fire-and-forget `_processQueue` loop run to quiescence.
Future<void> _flush() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

RenderRequest _req(
  String key, {
  int page = 0,
  RenderPriority priority = RenderPriority.prefetch,
  DateTime? requestedAt,
}) =>
    RenderRequest(
      cacheKey: key,
      pageIndex: page,
      priority: priority,
      requestedAt: requestedAt,
    );

/// Fake render function: records the order of renders and lets a test hold
/// individual renders open with a [Completer].
class _FakeRenderer {
  final rendered = <String>[];
  final gates = <String, Completer<void>>{};
  final failing = <String>{};
  int active = 0;
  int maxActive = 0;

  Future<void> call(RenderRequest r) async {
    rendered.add(r.cacheKey);
    active++;
    if (active > maxActive) maxActive = active;
    try {
      final gate = gates[r.cacheKey];
      if (gate != null) await gate.future;
      if (failing.contains(r.cacheKey)) throw StateError('render failed');
    } finally {
      active--;
    }
  }

  Completer<void> hold(String key) => gates[key] = Completer<void>();
}

void main() {
  late PdfRenderQueue queue;
  late _FakeRenderer renderer;
  late List<String> completed;

  setUp(() {
    queue = PdfRenderQueue();
    renderer = _FakeRenderer();
    completed = <String>[];
    queue.onRender = renderer.call;
    queue.onCompleted = completed.add;
  });

  group('RenderRequest ordering', () {
    test('lower priority value sorts first', () {
      final t = DateTime(2026);
      final visible =
          _req('a', priority: RenderPriority.visible, requestedAt: t);
      final prefetch = _req('b', requestedAt: t);
      expect(visible.compareTo(prefetch), lessThan(0));
      expect(prefetch.compareTo(visible), greaterThan(0));
    });

    test('same priority is FIFO by request time', () {
      final early = _req('a', requestedAt: DateTime(2026));
      final later = _req('b', requestedAt: DateTime(2026, 1, 2));
      expect(early.compareTo(later), lessThan(0));
    });

    test('same priority and same timestamp never compare equal', () {
      final t = DateTime(2026);
      final first = _req('a', requestedAt: t);
      final second = _req('b', requestedAt: t);
      expect(first.compareTo(second), lessThan(0));
      expect(second.compareTo(first), greaterThan(0));
    });

    test('equality is by cacheKey and isLowRes', () {
      final a = _req('k', priority: RenderPriority.visible);
      final b = _req('k', priority: RenderPriority.background);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(RenderRequest(
          cacheKey: 'k',
          pageIndex: 0,
          priority: RenderPriority.visible,
          isLowRes: true,
        )),
      );
    });
  });

  group('priority ordering', () {
    test('visible renders before prefetch queued earlier', () async {
      final gate = renderer.hold('busy');
      queue.enqueue(_req('busy', priority: RenderPriority.visible));
      queue.enqueue(_req('prefetch'));
      queue.enqueue(_req('visible', priority: RenderPriority.visible));

      gate.complete();
      await _flush();

      expect(renderer.rendered, ['busy', 'visible', 'prefetch']);
      expect(completed, ['busy', 'visible', 'prefetch']);
    });

    test('requests created in the same instant are all kept, FIFO', () async {
      final t = DateTime(2026);
      final gate = renderer.hold('busy');
      queue.enqueue(_req('busy'));
      for (var i = 0; i < 5; i++) {
        queue.enqueue(_req('p$i', requestedAt: t));
      }
      expect(queue.queueLength, 5);

      gate.complete();
      await _flush();

      expect(renderer.rendered, ['busy', 'p0', 'p1', 'p2', 'p3', 'p4']);
    });

    test('re-enqueue with higher priority upgrades, lower does not downgrade',
        () async {
      queue.onRender = null; // hold everything in the queue
      queue.enqueue(_req('k'));
      queue.enqueue(_req('k', priority: RenderPriority.visible));
      queue.enqueue(_req('j', priority: RenderPriority.adjacent));
      queue.enqueue(_req('j', priority: RenderPriority.background));
      expect(queue.queueLength, 2);

      queue.onRender = renderer.call;
      queue.enqueue(_req('z', priority: RenderPriority.thumbnail));
      await _flush();

      expect(renderer.rendered, ['k', 'j', 'z']);
    });

    test('onVisiblePageChanged queues visible, adjacent, then prefetch',
        () async {
      queue.onVisiblePageChanged(5, 'doc.pdf', 20);
      await _flush();

      // Cache keys are 1-based page numbers.
      expect(renderer.rendered, [
        'doc.pdf|6', // visible
        'doc.pdf|5', 'doc.pdf|7', // adjacent
        'doc.pdf|4', 'doc.pdf|8', 'doc.pdf|3', 'doc.pdf|9', // prefetch
      ]);
    });

    test('onVisiblePageChanged respects document bounds', () async {
      queue.onVisiblePageChanged(0, 'doc.pdf', 2);
      await _flush();
      expect(renderer.rendered, ['doc.pdf|1', 'doc.pdf|2']);
    });

    test('onScrollDirectionChanged prefetches up to 5 pages ahead', () {
      queue.onRender = null;
      queue.onScrollDirectionChanged(8, 'doc.pdf', 11, true);
      expect(queue.queueLength, 2); // pages 9 and 10 only
      queue.onScrollDirectionChanged(2, 'doc.pdf', 11, false);
      expect(queue.queueLength, 4); // + pages 1 and 0
      expect(queue.isQueued('doc.pdf|1'), isTrue);
      expect(queue.isQueued('doc.pdf|10'), isTrue);
    });
  });

  group('stale request cancellation', () {
    test('drops prefetch more than 5 pages from the new visible page', () {
      queue.onRender = null;
      queue.onVisiblePageChanged(0, 'doc.pdf', 30);
      queue.onScrollDirectionChanged(0, 'doc.pdf', 30, true);
      // visible 0, adjacent 1, prefetch 2..5
      expect(queue.queueLength, 6);

      queue.onVisiblePageChanged(20, 'doc.pdf', 30);

      for (final page in [3, 4, 5, 6]) {
        expect(queue.isQueued('doc.pdf|$page'), isFalse, reason: 'p$page');
      }
      // Non-prefetch requests survive; the new window is queued.
      expect(queue.isQueued('doc.pdf|1'), isTrue);
      expect(queue.isQueued('doc.pdf|2'), isTrue);
      for (final page in [18, 19, 20, 21, 22, 23, 24]) {
        expect(queue.isQueued('doc.pdf|$page'), isTrue, reason: 'p$page');
      }
    });

    test('keeps prefetch within 5 pages', () {
      queue.onRender = null;
      queue.enqueue(_req('near', page: 15));
      queue.onVisiblePageChanged(10, 'doc.pdf', 30);
      expect(queue.isQueued('near'), isTrue);
    });
  });

  group('completion and eviction', () {
    test('completed pages are not rendered again until evicted', () async {
      queue.enqueue(_req('k'));
      await _flush();
      expect(queue.isCompleted('k'), isTrue);

      queue.enqueue(_req('k'));
      await _flush();
      expect(renderer.rendered, ['k']);

      queue.markAsEvicted('k');
      expect(queue.isCompleted('k'), isFalse);
      queue.enqueue(_req('k'));
      await _flush();
      expect(renderer.rendered, ['k', 'k']);
    });

    test('markAsCompleted skips the render', () async {
      queue.markAsCompleted('k');
      queue.enqueue(_req('k'));
      await _flush();
      expect(renderer.rendered, isEmpty);
      expect(queue.completedCount, 1);
    });

    test('in-progress pages are not queued twice', () async {
      final gate = renderer.hold('k');
      queue.enqueue(_req('k'));
      expect(queue.isInProgress('k'), isTrue);
      queue.enqueue(_req('k', priority: RenderPriority.visible));
      expect(queue.queueLength, 0);

      gate.complete();
      await _flush();
      expect(renderer.rendered, ['k']);
      expect(queue.isInProgress('k'), isFalse);
    });

    test('a failed render is not marked completed and the queue continues',
        () async {
      renderer.failing.add('bad');
      queue.enqueue(_req('bad', priority: RenderPriority.visible));
      queue.enqueue(_req('good'));
      await _flush();

      expect(renderer.rendered, ['bad', 'good']);
      expect(queue.isCompleted('bad'), isFalse);
      expect(completed, ['good']);
      expect(queue.inProgressCount, 0);
    });
  });

  group('concurrency limit', () {
    test('never runs more than 2 renders at once', () async {
      final gates = [for (var i = 0; i < 6; i++) renderer.hold('p$i')];
      for (var i = 0; i < 6; i++) {
        queue.enqueue(_req('p$i'));
      }
      expect(queue.inProgressCount, lessThanOrEqualTo(2));

      for (final gate in gates) {
        gate.complete();
        await _flush();
        expect(queue.inProgressCount, lessThanOrEqualTo(2));
      }

      expect(renderer.maxActive, lessThanOrEqualTo(2));
      // Current behaviour: the loop awaits each render, so renders are
      // serial and the limit of 2 is never reached.
      expect(renderer.maxActive, 1);
      expect(renderer.rendered, ['p0', 'p1', 'p2', 'p3', 'p4', 'p5']);
      expect(queue.completedCount, 6);
    });

    test('nothing renders without an onRender callback', () async {
      queue.onRender = null;
      queue.enqueue(_req('k'));
      await _flush();
      expect(queue.isQueued('k'), isTrue);
      expect(queue.inProgressCount, 0);
    });
  });

  group('teardown', () {
    test('clear empties the queue but keeps completed pages', () async {
      queue.enqueue(_req('done'));
      await _flush();
      queue.onRender = null;
      queue.enqueue(_req('pending'));

      queue.clear();

      expect(queue.queueLength, 0);
      expect(queue.inProgressCount, 0);
      expect(queue.isCompleted('done'), isTrue);
    });

    test('reset drops queue, in-progress and completed state', () async {
      queue.enqueue(_req('done'));
      await _flush();
      queue.onRender = null;
      queue.enqueue(_req('pending'));

      queue.reset();

      expect(queue.queueLength, 0);
      expect(queue.completedCount, 0);
      expect(queue.isCompleted('done'), isFalse);
    });

    test('an in-flight render finishing after reset does not crash', () async {
      final gate = renderer.hold('k');
      queue.enqueue(_req('k'));
      queue.reset();
      gate.complete();
      await _flush();
      expect(queue.inProgressCount, 0);
      expect(renderer.rendered, ['k']);
      // Current behaviour: the stale render still marks itself completed.
      expect(queue.isCompleted('k'), isTrue);
    });
  });
}
