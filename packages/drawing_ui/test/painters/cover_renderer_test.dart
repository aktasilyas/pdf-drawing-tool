import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
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
  test('labelPlateRect is 64% wide, 3:1, in the upper third', () {
    const size = ui.Size(240, 320);
    final r = CoverRenderer.labelPlateRect(size);
    expect(r.width, closeTo(240 * 0.64, 0.001));
    expect(r.width / r.height, closeTo(3, 0.001));
    expect(r.center.dx, closeTo(120, 0.001));
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

  test('center pixel of the plate is the plate color', () async {
    for (final size in const [ui.Size(120, 160), ui.Size(240, 320)]) {
      final data = await _render(CoverFamily.leatherNavy, size);
      final c = CoverRenderer.labelPlateRect(size).center;
      final i = (c.dy.round() * size.width.round() + c.dx.round()) * 4;
      expect(data.getUint8(i), 0xFB);
      expect(data.getUint8(i + 1), 0xF9);
      expect(data.getUint8(i + 2), 0xF4);
    }
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
