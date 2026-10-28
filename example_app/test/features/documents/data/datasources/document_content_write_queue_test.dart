import 'dart:async';

import 'package:example_app/features/documents/data/datasources/document_content_write_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DocumentContentWriteQueue queue;

  setUp(() => queue = DocumentContentWriteQueue());

  test('a later write for the same id waits for the earlier one', () async {
    final log = <String>[];
    final slow = Completer<void>();

    final first = queue.enqueue('doc', () async {
      log.add('first start');
      await slow.future;
      log.add('first end');
    });
    final second = queue.enqueue('doc', () async => log.add('second'));

    await pumpEventQueue();
    expect(log, ['first start']);

    slow.complete();
    await Future.wait([first, second]);
    expect(log, ['first start', 'first end', 'second']);
  });

  test('writes for different ids do not wait for each other', () async {
    final slow = Completer<void>();
    final log = <String>[];

    unawaited(queue.enqueue('a', () => slow.future));
    await queue.enqueue('b', () async => log.add('b'));

    expect(log, ['b']);
    expect(queue.isPending('a'), isTrue);
    slow.complete();
  });

  test('an earlier failure goes to its caller and does not block', () async {
    final failing = queue.enqueue('doc', () async => throw StateError('x'));
    var ran = false;
    final next = queue.enqueue('doc', () async => ran = true);

    await expectLater(failing, throwsStateError);
    await next;
    expect(ran, isTrue);
  });

  test('forgets an id once its last write settles', () async {
    final slow = Completer<void>();
    final write = queue.enqueue('doc', () => slow.future);
    expect(queue.isPending('doc'), isTrue);

    slow.complete();
    await write;
    await pumpEventQueue();
    expect(queue.isPending('doc'), isFalse);
  });

  test('keeps the id while a newer write is still queued', () async {
    final slow = Completer<void>();
    final first = queue.enqueue('doc', () async {});
    unawaited(queue.enqueue('doc', () => slow.future));

    await first;
    await pumpEventQueue();
    expect(queue.isPending('doc'), isTrue);

    slow.complete();
    await pumpEventQueue();
    expect(queue.isPending('doc'), isFalse);
  });
}
