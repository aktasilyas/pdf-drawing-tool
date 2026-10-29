import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/page_rasterizer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rendering uses real async (picture.toImage), which never completes under
/// the FakeAsync zone of a plain [testWidgets].
void testRender(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

/// A 20x20 page whose single layer is fully covered by one black stroke.
Page _inkedPage(double layerOpacity) {
  final stroke = Stroke.create(
    style: StrokeStyle(color: 0xFF000000, thickness: 50),
    points: [
      DrawingPoint(x: 0, y: 10),
      DrawingPoint(x: 20, y: 10),
    ],
  );
  final page =
      Page.create(index: 0, size: const PageSize(width: 20, height: 20));
  return page.copyWith(layers: [
    Layer(
      id: 'l1',
      name: 'Ink',
      strokes: [stroke],
      opacity: layerOpacity,
    ),
  ]);
}

Future<int> _centerRed(Page page) async {
  final image = await PageRasterizer.render(page, width: 20, height: 20);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return data.buffer.asUint8List()[(10 * 20 + 10) * 4];
}

Future<Uint8List> _bytes(Page page) async {
  final image = await PageRasterizer.render(page, width: 20, height: 20);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return data.buffer.asUint8List();
}

void main() {
  testRender('an opaque layer renders ink at full strength', () async {
    expect(await _centerRed(_inkedPage(1)), lessThan(5));
  });

  testRender('a half-opacity layer lands between ink and paper', () async {
    expect(await _centerRed(_inkedPage(0.5)), inInclusiveRange(110, 145));
  });

  testRender('a zero-opacity layer leaves the blank page untouched', () async {
    final blank = await _bytes(
      Page.create(index: 0, size: const PageSize(width: 20, height: 20)),
    );
    expect(await _bytes(_inkedPage(0)), blank);
  });
}
