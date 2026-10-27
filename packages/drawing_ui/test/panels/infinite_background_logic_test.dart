import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/panels/infinite_background_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InfiniteBackgroundBuilder.patternOf', () {
    test('maps legacy and template backgrounds', () {
      PageBackground t(TemplatePattern p) =>
          PageBackground(type: BackgroundType.template, templatePattern: p);
      expect(InfiniteBackgroundBuilder.patternOf(PageBackground.blank),
          InfiniteBackgroundPattern.plain);
      expect(
          InfiniteBackgroundBuilder.patternOf(
              const PageBackground(type: BackgroundType.dotted)),
          InfiniteBackgroundPattern.dotted);
      expect(
          InfiniteBackgroundBuilder.patternOf(
              const PageBackground(type: BackgroundType.grid)),
          InfiniteBackgroundPattern.grid);
      expect(InfiniteBackgroundBuilder.patternOf(t(TemplatePattern.smallDots)),
          InfiniteBackgroundPattern.dotted);
      expect(InfiniteBackgroundBuilder.patternOf(t(TemplatePattern.largeGrid)),
          InfiniteBackgroundPattern.grid);
      expect(InfiniteBackgroundBuilder.patternOf(t(TemplatePattern.cornell)),
          InfiniteBackgroundPattern.plain);
    });
  });

  group('InfiniteBackgroundBuilder', () {
    test('pattern change keeps colour', () {
      const bg = PageBackground(
          type: BackgroundType.blank, color: InfiniteBackgroundColors.yellow);
      for (final p in InfiniteBackgroundPattern.values) {
        final next = InfiniteBackgroundBuilder.withPattern(bg, p);
        expect(next.color, InfiniteBackgroundColors.yellow);
        expect(InfiniteBackgroundBuilder.patternOf(next), p);
      }
    });

    test('colour change keeps pattern and spacing', () {
      const bg = PageBackground(
          type: BackgroundType.grid, gridSpacing: 25, lineColor: 0xFFCCCCCC);
      final next = InfiniteBackgroundBuilder.withColor(
          bg, InfiniteBackgroundColors.black);
      expect(next.type, BackgroundType.grid);
      expect(next.gridSpacing, 25);
      expect(next.color, InfiniteBackgroundColors.black);
      expect(next.lineColor, 0xFF444444);
      expect(
          InfiniteBackgroundBuilder.withColor(
                  next, InfiniteBackgroundColors.white)
              .lineColor,
          0xFFCCCCCC);
    });
  });

  test('colour groups', () {
    expect(InfiniteBackgroundColors.groupOf(0xFFFFFFFF),
        InfiniteBackgroundColors.white);
    expect(InfiniteBackgroundColors.groupOf(0xFFFFF8E1),
        InfiniteBackgroundColors.yellow);
    expect(InfiniteBackgroundColors.groupOf(0xFF000000),
        InfiniteBackgroundColors.black);
  });
}
