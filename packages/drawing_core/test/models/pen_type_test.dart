import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PenType enum', () {
    test('has 10 pen types', () {
      expect(PenType.values.length, 10);
    });

    test('contains all expected values', () {
      expect(PenType.values, contains(PenType.pencil));
      expect(PenType.values, contains(PenType.hardPencil));
      expect(PenType.values, contains(PenType.ballpointPen));
      expect(PenType.values, contains(PenType.gelPen));
      expect(PenType.values, contains(PenType.dashedPen));
      expect(PenType.values, contains(PenType.highlighter));
      expect(PenType.values, contains(PenType.brushPen));
      expect(PenType.values, contains(PenType.neonHighlighter));
    });
  });

  group('PenTypeConfig', () {
    test('pencil config', () {
      final config = PenType.pencil.config;
      expect(config.displayName, 'Pencil');
      expect(config.displayNameTr, 'Kurşun Kalem');
      expect(config.defaultThickness, 1.5);
      expect(config.maxThickness, 8.0);
      expect(config.texture, StrokeTexture.pencil);
      expect(config.nibShape, NibShape.circle);
    });

    test('hardPencil config', () {
      final config = PenType.hardPencil.config;
      expect(config.displayName, 'Hard Pencil');
      expect(config.displayNameTr, 'Sert Kalem');
      expect(config.defaultThickness, 1.0);
      expect(config.maxThickness, 5.0);
      expect(config.defaultOpacity, 0.7);
      expect(config.texture, StrokeTexture.pencil);
    });

    test('ballpointPen config', () {
      final config = PenType.ballpointPen.config;
      expect(config.displayName, 'Ballpoint Pen');
      expect(config.displayNameTr, 'Tükenmez Kalem');
      expect(config.defaultThickness, 1.5);
      expect(config.maxThickness, 5.0);
      expect(config.nibShape, NibShape.circle);
    });

    test('gelPen config', () {
      final config = PenType.gelPen.config;
      expect(config.displayName, 'Gel Pen');
      expect(config.displayNameTr, 'Jel Kalem');
      expect(config.defaultThickness, 2.0);
      expect(config.maxThickness, 8.0);
    });

    test('dashedPen config', () {
      final config = PenType.dashedPen.config;
      expect(config.displayName, 'Dashed Pen');
      expect(config.displayNameTr, 'Kesik Çizgi');
      expect(config.defaultThickness, 2.0);
      expect(config.pattern, StrokePattern.dashed);
      expect(config.dashPattern, [8.0, 4.0]);
    });

    test('highlighter config', () {
      final config = PenType.highlighter.config;
      expect(config.displayName, 'Highlighter');
      expect(config.displayNameTr, 'Fosforlu Kalem');
      expect(config.defaultThickness, 20.0);
      expect(config.minThickness, 10.0);
      expect(config.maxThickness, 40.0);
      expect(config.defaultOpacity, 0.4);
      expect(config.nibShape, NibShape.rectangle);
    });

    test('brushPen config', () {
      final config = PenType.brushPen.config;
      expect(config.displayName, 'Brush Pen');
      expect(config.displayNameTr, 'Fırça Kalem');
      expect(config.defaultThickness, 5.0);
      expect(config.maxThickness, 30.0);
      expect(config.nibShape, NibShape.ellipse);
    });

    test('neonHighlighter config', () {
      final config = PenType.neonHighlighter.config;
      expect(config.displayName, 'Neon Highlighter');
      expect(config.displayNameTr, 'Neon Fosforlu');
      expect(config.defaultThickness, 15.0);
      expect(config.minThickness, 8.0);
      expect(config.maxThickness, 30.0);
      expect(config.defaultOpacity, 0.8);
      expect(config.glowRadius, 8.0);
      expect(config.glowIntensity, 0.6);
      expect(config.nibShape, NibShape.rectangle);
    });

    test('rulerPen config', () {
      final config = PenType.rulerPen.config;
      expect(config.displayName, 'Ruler Pen');
      expect(config.displayNameTr, 'Cetvelli Kalem');
      expect(config.defaultThickness, 2.0);
      expect(config.minThickness, 0.5);
      expect(config.maxThickness, 10.0);
      expect(config.nibShape, NibShape.circle);
    });
  });

  group('PenTypeConfig defaults', () {
    test('default values are correct', () {
      // ballpointPen uses most defaults
      final config = PenType.ballpointPen.config;
      expect(config.minThickness, 0.1);
      expect(config.defaultOpacity, 1.0);
      expect(config.pattern, StrokePattern.solid);
      expect(config.texture, StrokeTexture.none);
      expect(config.glowRadius, 0.0);
      expect(config.glowIntensity, 0.0);
      expect(config.dashPattern, isNull);
    });
  });

  group('toStrokeStyle', () {
    test('creates StrokeStyle with default thickness', () {
      final style = PenType.pencil.toStrokeStyle(color: 0xFF000000);

      expect(style.color, 0xFF000000);
      expect(style.thickness, 1.5); // pencil default
      expect(style.texture, StrokeTexture.pencil);
      expect(style.nibShape, NibShape.circle);
    });

    test('creates StrokeStyle with custom thickness', () {
      final style = PenType.pencil.toStrokeStyle(
        color: 0xFF000000,
        thickness: 3.0,
      );

      expect(style.thickness, 3.0);
    });

    test('highlighter creates semi-transparent style', () {
      final style = PenType.highlighter.toStrokeStyle(color: 0xFFFFFF00);

      expect(style.opacity, 0.4);
      expect(style.nibShape, NibShape.rectangle);
      expect(style.thickness, 20.0);
    });

    test('dashedPen creates dashed style', () {
      final style = PenType.dashedPen.toStrokeStyle(color: 0xFF000000);

      expect(style.pattern, StrokePattern.dashed);
      expect(style.dashPattern, [8.0, 4.0]);
    });

    test('neonHighlighter creates glow style', () {
      final style = PenType.neonHighlighter.toStrokeStyle(color: 0xFF00FF00);

      expect(style.glowRadius, 8.0);
      expect(style.glowIntensity, 0.6);
      expect(style.opacity, 0.8);
      expect(style.nibShape, NibShape.rectangle);
    });

    test('brushPen creates ellipse nib style', () {
      final style = PenType.brushPen.toStrokeStyle(color: 0xFF0000FF);

      expect(style.nibShape, NibShape.ellipse);
      expect(style.thickness, 5.0);
    });

    test('rulerPen creates circle nib style', () {
      final style = PenType.rulerPen.toStrokeStyle(color: 0xFF000000);

      expect(style.nibShape, NibShape.circle);
      expect(style.thickness, 2.0);
    });

    test('all pen types create valid StrokeStyle', () {
      for (final penType in PenType.values) {
        final style = penType.toStrokeStyle(color: 0xFF000000);
        expect(style, isNotNull);
        expect(style.color, 0xFF000000);
        expect(style.thickness, greaterThan(0));
      }
    });
  });

  group('PenTypeConfig immutability', () {
    test('config values are consistent', () {
      final config1 = PenType.pencil.config;
      final config2 = PenType.pencil.config;

      expect(config1.defaultThickness, config2.defaultThickness);
      expect(config1.displayName, config2.displayName);
    });
  });
}
