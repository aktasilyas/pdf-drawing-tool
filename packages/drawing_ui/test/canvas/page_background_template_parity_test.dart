import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_painters.dart';
import 'package:drawing_ui/src/canvas/infinite_background_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/painters/template_pattern_painter.dart';

const _size = Size(595, 842);

Future<Uint8List> _render(CustomPainter painter, [Size size = _size]) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final image = await recorder
      .endRecording()
      .toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

PageBackground _withoutExtra(PageBackground bg) => PageBackground(
      type: bg.type,
      color: bg.color,
      lineColor: bg.lineColor,
      templatePattern: bg.templatePattern,
      templateSpacingMm: bg.templateSpacingMm,
      templateLineWidth: bg.templateLineWidth,
    );

void main() {
  for (final id in ['engineer_pad', 'calligraphy_copperplate']) {
    group(id, () {
      final template = TemplateRegistry.getById(id)!;
      final bg = PageBackground.fromTemplate(template);

      test('page painter matches TemplatePatternPainter.fromTemplate',
          () async {
        final expected = await _render(TemplatePatternPainter.fromTemplate(
          template,
          lineColor: Color(template.defaultLineColor),
          backgroundColor: Colors.transparent,
          pageSize: _size,
        ));
        final actual = await _render(PageBackgroundPatternPainter(
          background: bg,
        ));
        expect(actual, orderedEquals(expected));
      });

      test('still matches after a JSON round-trip', () async {
        final restored =
            PageBackground.fromJson(jsonDecode(jsonEncode(bg.toJson())));
        final expected = await _render(PageBackgroundPatternPainter(
          background: bg,
        ));
        final actual = await _render(PageBackgroundPatternPainter(
          background: restored,
        ));
        expect(actual, orderedEquals(expected));
      });

      test('negative control: without extraData the image differs', () async {
        final with_ = await _render(PageBackgroundPatternPainter(
          background: bg,
        ));
        final without = await _render(PageBackgroundPatternPainter(
          background: _withoutExtra(bg),
        ));
        expect(without, isNot(orderedEquals(with_)));
      });

      test('DynamicBackgroundPainter uses extraData', () async {
        final with_ = await _render(DynamicBackgroundPainter(background: bg));
        final without = await _render(
            DynamicBackgroundPainter(background: _withoutExtra(bg)));
        expect(without, isNot(orderedEquals(with_)));
      });

      test('InfiniteBackgroundPainter uses extraData', () async {
        final with_ = await _render(InfiniteBackgroundPainter(background: bg));
        final without = await _render(
            InfiniteBackgroundPainter(background: _withoutExtra(bg)));
        expect(without, isNot(orderedEquals(with_)));
      });
    });
  }

  group('picture cache key', () {
    final base =
        PageBackground.fromTemplate(TemplateRegistry.getById('medium_lined')!);

    test('templateLineWidth change produces a different image', () async {
      final thin = await _render(PageBackgroundPatternPainter(
        background: base.copyWith(templateLineWidth: 0.5),
      ));
      final thick = await _render(PageBackgroundPatternPainter(
        background: base.copyWith(templateLineWidth: 3),
      ));
      expect(thick, isNot(orderedEquals(thin)));
    });

    test('extraData change produces a different image', () async {
      final template = TemplateRegistry.getById('engineer_pad')!;
      final a = PageBackground.fromTemplate(template);
      final b = a.copyWith(templateExtraData: const {'showMarginLeft': false});
      final imgA = await _render(PageBackgroundPatternPainter(background: a));
      final imgB = await _render(PageBackgroundPatternPainter(background: b));
      expect(imgB, isNot(orderedEquals(imgA)));
    });
  });
}
