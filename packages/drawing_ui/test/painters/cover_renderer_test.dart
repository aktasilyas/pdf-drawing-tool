import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/painters/cover/cover_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ByteData> _render(Cover cover, ui.Size size) async {
  final recorder = ui.PictureRecorder();
  CoverRenderer.paint(ui.Canvas(recorder), size, cover);
  final image = await recorder
      .endRecording()
      .toImage(size.width.round(), size.height.round());
  return (await image.toByteData())!;
}

void main() {
  test('title zone is 3:1, centred on the face, in the upper third', () {
    const size = ui.Size(240, 320);
    final r = CoverRenderer.labelPlateRect(size);
    expect(r.width / r.height, closeTo(3, 0.001));
    expect(r.width, lessThan(240 * 0.74));
    expect(r.left, greaterThan(240 * 0.08)); // clear of the spine
    expect(r.bottom, lessThan(320 / 3));
  });

  test('every family cover renders deterministically', () async {
    for (final cover in CoverFamily.all) {
      final a = await _render(cover, const ui.Size(120, 160));
      final b = await _render(cover, const ui.Size(120, 160));
      expect(a.buffer.asUint8List(), equals(b.buffer.asUint8List()),
          reason: cover.id);
    }
  });

  test('kraft label plate stays close to the paper colour', () async {
    const size = ui.Size(240, 320);
    final data = await _render(CoverFamily.kraftNatural, size);
    final c = CoverRenderer.labelPlateRect(size).center;
    final i = (c.dy.round() * size.width.round() + c.dx.round()) * 4;
    expect(data.getUint8(i), greaterThan(0xD8));
    expect(data.getUint8(i + 1), greaterThan(0xD0));
    expect(data.getUint8(i + 2), greaterThan(0xB0));
  });

  test('notebook layout: transparent corner, opaque board, square spine',
      () async {
    const size = ui.Size(240, 320);
    final data = await _render(CoverFamily.leatherCognac, size);
    int alpha(int x, int y) => data.getUint8((y * 240 + x) * 4 + 3);
    expect(alpha(1, 1), 0); // outside the board (margin)
    expect(alpha(120, 160), 255); // board
    expect(alpha(5, 5), 255); // square spine corner
  });

  test('page block runs under the spine at the bottom-left corner', () async {
    const size = ui.Size(240, 320);
    final data = await _render(CoverFamily.linenSage, size);
    int alpha(int x, int y) => data.getUint8((y * 240 + x) * 4 + 3);
    final g = CoverGeometry.of(size);
    final x = (g.cover.left + g.spineWidth / 2).round();
    final y = (g.cover.bottom + g.pageEdge).floor();
    expect(alpha(x, y), 255); // opaque page edge below the spine
    // Nothing is cast into the margin left of the book.
    final left = (g.cover.left - 1).floor();
    expect(alpha(left, g.cover.center.dy.round()), 0);
  });

  test('loaded photographic texture adds grain to the board', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await CoverTextureStore.ensureLoaded();
    const size = ui.Size(240, 320);
    final data = await _render(CoverFamily.leatherCognac, size);
    final distinct = <int>{};
    for (var y = 150; y < 250; y++) {
      for (var x = 100; x < 200; x++) {
        distinct.add(data.getUint32((y * 240 + x) * 4));
      }
    }
    // Assets are only bundled when running via the app; skip silently if not.
    if (!CoverTextureStore.isLoaded) return;
    expect(distinct.length, greaterThan(200));
  });

  test('texture is visible outside the plate', () async {
    const size = ui.Size(240, 320);
    final data = await _render(CoverFamily.feltMustard, size);
    final distinct = <int>{};
    for (var y = 200; y < 300; y++) {
      for (var x = 100; x < 200; x++) {
        distinct.add(data.getUint32((y * 240 + x) * 4));
      }
    }
    expect(distinct.length, greaterThan(1));
  });

  test('needsRepaint compares cover ids', () {
    expect(
        CoverRenderer.needsRepaint(
            CoverFamily.linenSage, CoverFamily.linenSage),
        isFalse);
    expect(
        CoverRenderer.needsRepaint(
            CoverFamily.linenSage, CoverFamily.linenSand),
        isTrue);
  });
}
