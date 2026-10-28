import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _pngBytes() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 1, 1),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  final image = await recorder.endRecording().toImage(1, 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('image_cache_test');
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<void> writeImage(tester) async {
    await tester.runAsync(() async {
      final dir = Directory('${root.path}/elyanotes_images')..createSync();
      File('${dir.path}/a.png').writeAsBytesSync(await _pngBytes());
    });
  }

  testWidgets('loads a relative key through the resolver', (tester) async {
    await writeImage(tester);
    final cache = ImageCacheManager(paths: PdfPathResolver(root.path));
    addTearDown(cache.dispose);
    await tester.runAsync(() => cache.loadImage('elyanotes_images/a.png'));
    expect(cache.get('elyanotes_images/a.png'), isNotNull);
  });

  testWidgets('loads a legacy absolute key re-rooted', (tester) async {
    await writeImage(tester);
    const legacy = '/data/user/0/old.pkg/app_flutter/elyanotes_images/a.png';
    final cache = ImageCacheManager(paths: PdfPathResolver(root.path));
    addTearDown(cache.dispose);
    await tester.runAsync(() => cache.loadImage(legacy));
    expect(cache.get(legacy), isNotNull);
  });

  testWidgets('passthrough does not find a relative key', (tester) async {
    await writeImage(tester);
    final cache = ImageCacheManager();
    addTearDown(cache.dispose);
    await tester.runAsync(() => cache.loadImage('elyanotes_images/a.png'));
    expect(cache.get('elyanotes_images/a.png'), isNull);
  });
}
