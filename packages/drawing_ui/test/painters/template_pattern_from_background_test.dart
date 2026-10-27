import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

Future<ByteData> _render(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final image = await recorder
      .endRecording()
      .toImage(size.width.toInt(), size.height.toInt());
  return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
}

int _alphaAt(ByteData data, int width, int x, int y) =>
    data.getUint8((y * width + x) * 4 + 3);

void main() {
  const size = Size(200, 300);

  group('TemplatePatternPainter.fromBackground', () {
    test('maps all fields and scales lineWidth', () {
      const bg = PageBackground(
        type: BackgroundType.template,
        templatePattern: TemplatePattern.cornell,
        templateSpacingMm: 7,
        templateLineWidth: 0.4,
        templateExtraData: {'leftMarginRatio': 0.28},
      );
      final painter = TemplatePatternPainter.fromBackground(
        bg,
        lineColor: Colors.red,
        pageSize: size,
        lineWidthScale: 2,
      );
      expect(painter.pattern, TemplatePattern.cornell);
      expect(painter.spacingMm, 7);
      expect(painter.lineWidth, closeTo(0.8, 1e-9));
      expect(painter.lineColor, Colors.red);
      expect(painter.backgroundColor, Colors.transparent);
      expect(painter.pageSize, size);
      expect(painter.extraData, {'leftMarginRatio': 0.28});
    });

    test('uses defaults when spacing and width are null', () {
      const bg = PageBackground(
        type: BackgroundType.template,
        templatePattern: TemplatePattern.mediumLines,
      );
      final painter = TemplatePatternPainter.fromBackground(
        bg,
        lineColor: Colors.red,
        pageSize: size,
      );
      expect(painter.spacingMm, 8.0);
      expect(painter.lineWidth, 0.5);
      expect(painter.extraData, isNull);
    });
  });

  group('Cornell margins', () {
    TemplatePatternPainter cornell(Map<String, dynamic>? extra) =>
        TemplatePatternPainter(
          pattern: TemplatePattern.cornell,
          spacingMm: 8,
          lineWidth: 1,
          lineColor: Colors.black,
          backgroundColor: Colors.transparent,
          pageSize: size,
          extraData: extra,
        );

    test('leftMarginRatio positions the cue column', () async {
      final data = await _render(cornell({'leftMarginRatio': 0.28}), size);
      expect(_alphaAt(data, 200, 56, 10), greaterThan(0));
      expect(_alphaAt(data, 200, 60, 10), 0);
    });

    test('default is 0.3 of the width', () async {
      final data = await _render(cornell(null), size);
      expect(_alphaAt(data, 200, 60, 10), greaterThan(0));
    });

    test('absolute marginLeft (int) is a fallback and does not throw',
        () async {
      final data = await _render(cornell({'marginLeft': 100}), size);
      expect(_alphaAt(data, 200, 100, 10), greaterThan(0));
    });

    test('ratio wins over absolute key', () async {
      final data = await _render(
          cornell({'leftMarginRatio': 0.28, 'marginLeft': 100}), size);
      expect(_alphaAt(data, 200, 56, 10), greaterThan(0));
      expect(_alphaAt(data, 200, 100, 10), 0);
    });

    test('bottomSummaryRatio positions the summary divider', () async {
      final data = await _render(cornell({'bottomSummaryRatio': 0.25}), size);
      // divider at y = 300 - 75 = 225
      expect(_alphaAt(data, 200, 20, 225), greaterThan(0));
      expect(_alphaAt(data, 200, 20, 240), 0);
    });
  });
}
