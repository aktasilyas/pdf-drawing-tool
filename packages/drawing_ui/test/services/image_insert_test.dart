import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_ui/src/services/image_insert.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _png() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 4, 4), ui.Paint());
  final image = await recorder.endRecording().toImage(4, 4);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('image_insert'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<ImageInsertResult?> run(Future<String?> Function() pick,
          [String? root]) =>
      insertPickedImage(pick, documentsRoot: () async => root ?? tmp.path);

  int storedCount() {
    final dir = Directory('${tmp.path}/elyanotes_images');
    return dir.existsSync() ? dir.listSync().length : 0;
  }

  test('cancelled picker returns null', () async {
    expect(await run(() async => null), isNull);
  });

  test('picker exception maps to pickerFailed', () async {
    final r = await run(() async => throw Exception('boom'));
    expect(r!.error, ImageInsertError.pickerFailed);
  });

  test('undecodable file is rejected and nothing is copied', () async {
    final f = File('${tmp.path}/bad.jpg')..writeAsStringSync('not an image');
    final r = await run(() async => f.path);
    expect(r!.error, ImageInsertError.unreadable);
    expect(storedCount(), 0);
  });

  test('missing file maps to unreadable', () async {
    final r = await run(() async => '${tmp.path}/nope.png');
    expect(r!.error, ImageInsertError.unreadable);
  });

  test('copy failure maps to cannotWrite and leaves no file', () async {
    final f = File('${tmp.path}/ok.png')..writeAsBytesSync(await _png());
    // documentsRoot is a file, so the images dir cannot be created.
    final blocker = File('${tmp.path}/blocker')..writeAsStringSync('x');
    final r = await run(() async => f.path, blocker.path);
    expect(r!.error, ImageInsertError.cannotWrite);
    expect(storedCount(), 0);
  });

  test('valid image is stored', () async {
    final f = File('${tmp.path}/ok.png')..writeAsBytesSync(await _png());
    final r = await run(() async => f.path);
    expect(r!.error, isNull);
    expect(File(r.storedPath!).existsSync(), isTrue);
  });
}
