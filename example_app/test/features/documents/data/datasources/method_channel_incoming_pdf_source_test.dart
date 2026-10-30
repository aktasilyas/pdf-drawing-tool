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

  Map<String, Object?> errorMap(String name, Object? reason) => {
        'name': name,
        'reason': reason,
      };

  IncomingPdfFailure failure(String name, IncomingPdfFailureReason reason) =>
      IncomingPdfFailure(name: name, reason: reason);

  Future<void> pushFromPlatform(Object? arguments, {String method = 'onPdf'}) {
    return messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall(method, arguments)),
      (_) {},
    );
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  test('cold start: PDFs returned by ready are emitted in order', () async {
    answerReady(() => [map('a.pdf'), map('b.pdf')]);
    final items = <IncomingPdfEvent>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(items, [pdf('a.pdf'), pdf('b.pdf')]);
  });

  test('warm start: onPdf from the platform is emitted', () async {
    answerReady(() => <Object?>[]);
    final items = <IncomingPdfEvent>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await pushFromPlatform(map('w.pdf'));
    await pumpEventQueue();
    expect(items, [pdf('w.pdf')]);
  });

  test('cold and warm PDFs both arrive', () async {
    answerReady(() => [map('a.pdf')]);
    final items = <IncomingPdfEvent>[];
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
    final items = <IncomingPdfEvent>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await pushFromPlatform('garbage');
    await pumpEventQueue();
    expect(items, [pdf('ok.pdf')]);
  });

  test('cold start: failures returned by ready keep their place', () async {
    answerReady(
      () => [
        map('a.pdf'),
        errorMap('full.pdf', 'storageFull'),
        errorMap('gone.pdf', 'unreadable'),
      ],
    );
    final items = <IncomingPdfEvent>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(items, [
      pdf('a.pdf'),
      failure('full.pdf', IncomingPdfFailureReason.storageFull),
      failure('gone.pdf', IncomingPdfFailureReason.unreadable),
    ]);
  });

  test('warm start: onPdfError from the platform is emitted', () async {
    answerReady(() => <Object?>[]);
    final items = <IncomingPdfEvent>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await pushFromPlatform(
      errorMap('full.pdf', 'storageFull'),
      method: 'onPdfError',
    );
    await pumpEventQueue();
    expect(items, [failure('full.pdf', IncomingPdfFailureReason.storageFull)]);
  });

  test('an unknown failure reason is reported as unreadable', () async {
    answerReady(() => [errorMap('odd.pdf', 'somethingNew')]);
    final items = <IncomingPdfEvent>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(items, [failure('odd.pdf', IncomingPdfFailureReason.unreadable)]);
  });

  test('malformed failure payloads are skipped', () async {
    answerReady(
      () => [
        {'reason': 'storageFull'},
        errorMap('no-reason.pdf', 42),
        {'name': 7, 'reason': 'unreadable'},
      ],
    );
    final items = <IncomingPdfEvent>[];
    final sub = MethodChannelIncomingPdfSource().watch().listen(items.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await pushFromPlatform('garbage', method: 'onPdfError');
    await pushFromPlatform({'name': 'x.pdf'}, method: 'onPdfError');
    await pumpEventQueue();
    expect(items, isEmpty);
  });
}
