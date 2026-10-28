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

late Directory root;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  budgetTests();
}

Future<ui.Image> _solid(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint(),
  );
  return recorder.endRecording().toImage(w, h);
}

void budgetTests() {
  testWidgets('stays within the byte budget and evicts least recently used',
      (tester) async {
    await tester.runAsync(() async {
      // Each 100x100 image is 40,000 bytes; budget fits two.
      final cache = ImageCacheManager(byteBudget: 80000);
      addTearDown(cache.dispose);
      cache.debugPut('a', await _solid(100, 100));
      cache.debugPut('b', await _solid(100, 100));
      cache.get('a'); // 'b' is now the oldest
      cache.debugPut('c', await _solid(100, 100));
      expect(cache.cachedBytes, lessThanOrEqualTo(80000));
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), isNotNull);
      expect(cache.get('c'), isNotNull);
    });
  });

  testWidgets('decodes oversized images within the max edge', (tester) async {
    late ImageCacheManager cache;
    await tester.runAsync(() async {
      final big = await _solid(4096, 2048);
      final data = await big.toByteData(format: ui.ImageByteFormat.png);
      big.dispose();
      File('${root.path}/big.png').writeAsBytesSync(data!.buffer.asUint8List());
      cache = ImageCacheManager(paths: PdfPathResolver(root.path));
      await cache.loadImage('big.png');
    });
    addTearDown(cache.dispose);
    final image = cache.get('big.png')!;
    expect(image.width, ImageCacheManager.maxDecodeEdge);
    expect(image.height, ImageCacheManager.maxDecodeEdge ~/ 2);
  });
}
