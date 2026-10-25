import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reference_strokes.dart';

const ui.Color _paper = ui.Color(0xFFFFF3C4);

ui.Image _render(PenType type) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, kReferenceWidth, kReferenceHeight),
    ui.Paint()..color = _paper,
  );
  final renderer = FlutterStrokeRenderer();
  for (final s in referenceStrokes(type)) {
    renderer.renderStroke(canvas, s);
  }
  return recorder
      .endRecording()
      .toImageSync(kReferenceWidth.toInt(), kReferenceHeight.toInt());
}

void main() {
  const presets = {
    'fountain': PenType.fountainPen,
    'ballpoint': PenType.ballpointPen,
    'brush': PenType.brushPen,
    'highlighter': PenType.highlighter,
    'pencil': PenType.pencil,
  };
  presets.forEach((name, type) {
    testWidgets('pen preset golden: $name', (tester) async {
      final image = (await tester.runAsync(() async => _render(type)))!;
      await expectLater(image, matchesGoldenFile('pen_preset_$name.png'));
    });
  });
}
