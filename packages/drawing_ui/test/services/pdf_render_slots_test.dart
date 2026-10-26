import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/pdf_render_slots.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('PdfRenderSlots', () {
    test('grants slots up to the limit', () async {
      final slots = PdfRenderSlots(maxConcurrent: 2);
      expect(await slots.acquire('a'), isTrue);
      expect(await slots.acquire('b'), isTrue);
      expect(slots.activeCount, 2);
    });

    test('a duplicate key is refused without waiting', () async {
      final slots = PdfRenderSlots(maxConcurrent: 2);
      expect(await slots.acquire('a'), isTrue);
      expect(await slots.acquire('a'), isFalse);
      expect(slots.activeCount, 1);
    });

    test('waits for a slot instead of giving up, newest waiter first',
        () async {
      final slots = PdfRenderSlots(maxConcurrent: 1);
      await slots.acquire('busy');

      final granted = <String>[];
      slots.acquire('old').then((_) => granted.add('old'));
      slots.acquire('new').then((_) => granted.add('new'));
      await _settle();
      expect(granted, isEmpty);
      expect(slots.waitingCount, 2);

      slots.release('busy');
      await _settle();
      expect(granted, ['new']);

      slots.release('new');
      await _settle();
      expect(granted, ['new', 'old']);
      expect(slots.activeCount, 1);

      slots.release('old');
      expect(slots.activeCount, 0);
    });

    test('release frees the key on every exit path', () async {
      final slots = PdfRenderSlots(maxConcurrent: 1);
      await slots.acquire('a');
      slots.release('a');
      expect(slots.isBusy('a'), isFalse);
      expect(await slots.acquire('a'), isTrue);
    });

    test('a waiting key counts as busy', () async {
      final slots = PdfRenderSlots(maxConcurrent: 1);
      await slots.acquire('busy');
      slots.acquire('queued');
      expect(slots.isBusy('queued'), isTrue);
    });

    test('releasing an unknown key does not free a slot', () async {
      final slots = PdfRenderSlots(maxConcurrent: 1);
      await slots.acquire('a');
      slots.release('nope');
      expect(slots.activeCount, 1);
    });

    test('whenIdle completes when the key is released', () async {
      final slots = PdfRenderSlots(maxConcurrent: 1);
      await slots.acquire('a');
      var idle = false;
      slots.whenIdle('a').then((_) => idle = true);
      await _settle();
      expect(idle, isFalse);
      slots.release('a');
      await _settle();
      expect(idle, isTrue);
      await slots.whenIdle('never-claimed');
    });
  });
}
