import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tolerant_golden_comparator.dart';

const _side = 100; // 10 000 px: one pixel is 0.01 %.

/// White [_side]×[_side] PNG with the pixels at [black] (x, y) set to black.
Future<Uint8List> _png({List<(int, int)> black = const [], int side = _side}) {
  final pixels = Uint8List(side * side * 4)..fillRange(0, side * side * 4, 255);
  for (final (x, y) in black) {
    final i = (y * side + x) * 4;
    pixels.setRange(i, i + 3, const [0, 0, 0]);
  }
  final done = Completer<Uint8List>();
  ui.decodeImageFromPixels(pixels, side, side, ui.PixelFormat.rgba8888,
      (image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    done.complete(data!.buffer.asUint8List());
  });
  return done.future;
}

List<(int, int)> _block(int size) => [
      for (var x = 0; x < size; x++)
        for (var y = 0; y < size; y++) (x, y),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late TolerantGoldenFileComparator comparator;
  final golden = Uri.parse('golden.png');

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('tolerant_golden_');
    File('${dir.path}/golden.png').writeAsBytesSync(await _png());
    comparator = TolerantGoldenFileComparator(
      Uri.file('${dir.path}/fake_test.dart'),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('identical image passes', () async {
    expect(await comparator.compare(await _png(), golden), isTrue);
  });

  test('a 1-pixel diff passes', () async {
    final bytes = await _png(black: [(50, 50)]);
    expect(await comparator.compare(bytes, golden), isTrue);
  });

  test('a diff exactly at the tolerance passes', () async {
    // 5 px = 0.05 %.
    final bytes = await _png(black: [for (var x = 0; x < 5; x++) (x, 0)]);
    expect(await comparator.compare(bytes, golden), isTrue);
  });

  test('a diff just above the tolerance fails', () async {
    // 6 px = 0.06 % > 0.05 %.
    final bytes = await _png(black: [for (var x = 0; x < 6; x++) (x, 0)]);
    await expectLater(
      comparator.compare(bytes, golden),
      throwsA(isA<FlutterError>()),
    );
  });

  test('a visible change fails', () async {
    final bytes = await _png(black: _block(20)); // 4 %.
    await expectLater(
      comparator.compare(bytes, golden),
      throwsA(isA<FlutterError>()),
    );
  });

  test('a size change fails', () async {
    final bytes = await _png(side: 101);
    await expectLater(
      comparator.compare(bytes, golden),
      throwsA(isA<FlutterError>()),
    );
  });

  test('flutter_test_config installs the tolerant comparator', () {
    expect(goldenFileComparator, isA<TolerantGoldenFileComparator>());
  });
}
