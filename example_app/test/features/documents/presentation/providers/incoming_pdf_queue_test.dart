import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';
import '../../../../helpers/fake_incoming_pdf_source.dart';

void main() {
  const a = IncomingPdf(path: '/a.pdf', name: 'a.pdf', size: 1);
  const b = IncomingPdf(path: '/b.pdf', name: 'b.pdf', size: 2);

  late FakeIncomingPdfSource source;
  late ProviderContainer container;

  setUp(() {
    source = FakeIncomingPdfSource();
    container = ProviderContainer(
      overrides: [incomingPdfSourceProvider.overrideWithValue(source)],
    );
  });

  tearDown(() => container.dispose());

  List<IncomingPdf> queue() => container.read(incomingPdfQueueProvider);

  test('items are queued in arrival order', () async {
    expect(queue(), isEmpty);
    source.emit(a);
    source.emit(b);
    await pumpEventQueue();
    expect(queue(), [a, b]);
  });

  test('remove drops only the given item', () async {
    expect(queue(), isEmpty);
    source.emit(a);
    source.emit(b);
    await pumpEventQueue();
    container.read(incomingPdfQueueProvider.notifier).remove(queue().first);
    expect(queue(), [b]);
  });

  test('disposing the container cancels the source subscription', () {
    final otherSource = FakeIncomingPdfSource();
    final other = ProviderContainer(
      overrides: [incomingPdfSourceProvider.overrideWithValue(otherSource)],
    );
    other.read(incomingPdfQueueProvider);
    expect(otherSource.hasListener, isTrue);
    other.dispose();
    expect(otherSource.hasListener, isFalse);
  });
}
