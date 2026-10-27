import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reference_strokes.dart';

/// Page thumbnails rendered with the canvas painters (#256): structured
/// templates and highlighter / pencil ink. Rendered at 300x424 so the detail
/// is reviewable; the app renders the same pipeline at 150x200.

Page _page(TemplatePattern pattern, {List<Stroke> strokes = const []}) {
  final page = Page.create(
    index: 0,
    size: PageSize.a4Portrait,
    background: PageBackground(
      type: BackgroundType.template,
      templatePattern: pattern,
      templateSpacingMm: pattern.defaultSpacingMm,
      templateLineWidth: pattern.defaultLineWidth,
      lineColor: 0xFFB0B0B0,
    ),
  );
  return page.copyWith(
    layers: [
      page.layers.first.copyWith(
        strokes: strokes,
        elementOrder: [for (final s in strokes) s.id],
      ),
    ],
  );
}

Future<ui.Image> _thumbnail(Page page) async {
  final png = await ThumbnailGenerator.generate(page, width: 300, height: 424);
  final codec = await ui.instantiateImageCodec(png!);
  return (await codec.getNextFrame()).image;
}

void main() {
  final cases = {
    'cornell': _page(TemplatePattern.cornell),
    'weekly_planner': _page(TemplatePattern.weeklyPlanner),
    'highlighter': _page(
      TemplatePattern.mediumLines,
      strokes: referenceStrokes(PenType.highlighter),
    ),
    'pencil': _page(
      TemplatePattern.blank,
      strokes: referenceStrokes(PenType.pencil),
    ),
  };
  cases.forEach((name, page) {
    testWidgets('thumbnail golden: $name', (tester) async {
      final image = (await tester.runAsync(() => _thumbnail(page)))!;
      await expectLater(image, matchesGoldenFile('thumbnail_$name.png'));
    });
  });
}
