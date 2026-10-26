import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelIncomingPdfSource.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Map<String, Object?> map(String name, {Object? size = 10}) => {
        'path': '/cache/incoming/$name',
        'name': name,
        'size': size,
      };

  IncomingPdf pdf(String name) =>
      IncomingPdf(path: '/cache/incoming/$name', name: name, size: 10);

  void answerReady(Object? Function() answer) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'ready');
      return answer();
    });
  }

  Future<void> pushFromPlatform(Object? arguments) {
    return messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall('onPdf', arguments)),
      (_) {},
    );
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  test('cold start: PDFs returned by ready are emitted in order', () async {
    answerReady(() => [map('a.pdf'), map('b.pdf')]);
    final items = <IncomingPdf>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(items, [pdf('a.pdf'), pdf('b.pdf')]);
  });

  test('warm start: onPdf from the platform is emitted', () async {
    answerReady(() => <Object?>[]);
    final items = <IncomingPdf>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await pushFromPlatform(map('w.pdf'));
    await pumpEventQueue();
    expect(items, [pdf('w.pdf')]);
  });

  test('cold and warm PDFs both arrive', () async {
    answerReady(() => [map('a.pdf')]);
    final items = <IncomingPdf>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await pushFromPlatform(map('b.pdf'));
    await pumpEventQueue();
    expect(items, [pdf('a.pdf'), pdf('b.pdf')]);
  });

  test('a missing native side gives an empty, closed stream', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final items = await MethodChannelIncomingPdfSource().watch().toList();
    expect(items, isEmpty);
  });

  test('malformed maps are skipped', () async {
    final replies = <Object?>[
      'not a map',
      {'path': '/x.pdf'},
      map('bad-size.pdf', size: '10'),
      {'path': '', 'name': 'empty.pdf', 'size': 1},
      map('ok.pdf'),
    ];
    answerReady(() => replies);
    final items = <IncomingPdf>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await pushFromPlatform('garbage');
    await pumpEventQueue();
    expect(items, [pdf('ok.pdf')]);
  });
}
