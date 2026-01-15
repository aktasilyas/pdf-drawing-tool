import 'package:test/test.dart';
import 'package:drawing_core/src/models/stroke_style.dart';

void main() {
  group('NibShape enum', () {
    test('has correct values', () {
      expect(NibShape.values.length, 3);
      expect(NibShape.values, contains(NibShape.circle));
      expect(NibShape.values, contains(NibShape.ellipse));
      expect(NibShape.values, contains(NibShape.rectangle));
    });
  });

  group('DrawingBlendMode enum', () {
    test('has correct values', () {
      expect(DrawingBlendMode.values.length, 6);
      expect(DrawingBlendMode.values, contains(DrawingBlendMode.normal));
      expect(DrawingBlendMode.values, contains(DrawingBlendMode.multiply));
      expect(DrawingBlendMode.values, contains(DrawingBlendMode.screen));
      expect(DrawingBlendMode.values, contains(DrawingBlendMode.overlay));
      expect(DrawingBlendMode.values, contains(DrawingBlendMode.darken));
      expect(DrawingBlendMode.values, contains(DrawingBlendMode.lighten));
    });
  });

  group('StrokePattern enum', () {
    test('has correct values', () {
      expect(StrokePattern.values.length, 3);
      expect(StrokePattern.values, contains(StrokePattern.solid));
      expect(StrokePattern.values, contains(StrokePattern.dashed));
      expect(StrokePattern.values, contains(StrokePattern.dotted));
    });
  });

  group('StrokeTexture enum', () {
    test('has correct values', () {
      expect(StrokeTexture.values.length, 4);
      expect(StrokeTexture.values, contains(StrokeTexture.none));
      expect(StrokeTexture.values, contains(StrokeTexture.pencil));
      expect(StrokeTexture.values, contains(StrokeTexture.chalk));
      expect(StrokeTexture.values, contains(StrokeTexture.watercolor));
    });
  });

  group('StrokeStyle', () {
    group('Constructor', () {
      test('creates with required parameters', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
        );

        expect(style.color, 0xFF000000);
        expect(style.thickness, 2.0);
        expect(style.opacity, 1.0); // default
        expect(style.nibShape, NibShape.circle); // default
        expect(style.blendMode, DrawingBlendMode.normal); // default
        expect(style.isEraser, false); // default
      });

      test('creates with all parameters', () {
        final style = StrokeStyle(
          color: 0xFFFF0000,
          thickness: 5.0,
          opacity: 0.5,
          nibShape: NibShape.ellipse,
          blendMode: DrawingBlendMode.multiply,
          isEraser: true,
        );

        expect(style.color, 0xFFFF0000);
        expect(style.thickness, 5.0);
        expect(style.opacity, 0.5);
        expect(style.nibShape, NibShape.ellipse);
        expect(style.blendMode, DrawingBlendMode.multiply);
        expect(style.isEraser, true);
      });

      test('clamps thickness to valid range', () {
        final tooThin = StrokeStyle(color: 0xFF000000, thickness: 0.01);
        final tooThick = StrokeStyle(color: 0xFF000000, thickness: 100.0);

        expect(tooThin.thickness, 0.1);
        expect(tooThick.thickness, 50.0);
      });

      test('clamps opacity to valid range', () {
        final tooLow = StrokeStyle(color: 0xFF000000, thickness: 2.0, opacity: -0.5);
        final tooHigh = StrokeStyle(color: 0xFF000000, thickness: 2.0, opacity: 1.5);

        expect(tooLow.opacity, 0.0);
        expect(tooHigh.opacity, 1.0);
      });
    });

    group('Factory: pen', () {
      test('creates with default values', () {
        final style = StrokeStyle.pen();

        expect(style.color, 0xFF000000); // black
        expect(style.thickness, 2.0);
        expect(style.opacity, 1.0);
        expect(style.nibShape, NibShape.circle);
        expect(style.isEraser, false);
      });

      test('creates with custom color and thickness', () {
        final style = StrokeStyle.pen(
          color: 0xFFFF0000,
          thickness: 3.0,
        );

        expect(style.color, 0xFFFF0000);
        expect(style.thickness, 3.0);
        expect(style.nibShape, NibShape.circle);
      });
    });

    group('Factory: highlighter', () {
      test('creates with default values', () {
        final style = StrokeStyle.highlighter();

        expect(style.color, 0xFFFFEB3B); // yellow
        expect(style.thickness, 20.0);
        expect(style.opacity, 0.5);
        expect(style.nibShape, NibShape.rectangle);
        expect(style.isEraser, false);
      });

      test('creates with custom color and thickness', () {
        final style = StrokeStyle.highlighter(
          color: 0xFF00FF00,
          thickness: 15.0,
        );

        expect(style.color, 0xFF00FF00);
        expect(style.thickness, 15.0);
        expect(style.opacity, 0.5);
        expect(style.nibShape, NibShape.rectangle);
      });
    });

    group('Factory: brush', () {
      test('creates with default values', () {
        final style = StrokeStyle.brush();

        expect(style.color, 0xFF000000); // black
        expect(style.thickness, 5.0);
        expect(style.opacity, 1.0);
        expect(style.nibShape, NibShape.ellipse);
        expect(style.isEraser, false);
      });

      test('creates with custom color and thickness', () {
        final style = StrokeStyle.brush(
          color: 0xFF0000FF,
          thickness: 8.0,
        );

        expect(style.color, 0xFF0000FF);
        expect(style.thickness, 8.0);
        expect(style.nibShape, NibShape.ellipse);
      });
    });

    group('Factory: eraser', () {
      test('creates with default values', () {
        final style = StrokeStyle.eraser();

        expect(style.color, 0xFFFFFFFF); // white
        expect(style.thickness, 10.0);
        expect(style.opacity, 1.0);
        expect(style.isEraser, true);
      });

      test('creates with custom thickness', () {
        final style = StrokeStyle.eraser(thickness: 15.0);

        expect(style.color, 0xFFFFFFFF);
        expect(style.thickness, 15.0);
        expect(style.isEraser, true);
      });
    });

    group('Color helpers', () {
      test('getAlpha returns correct value', () {
        final style = StrokeStyle(color: 0x80FF0000, thickness: 2.0);
        expect(style.getAlpha(), 0x80); // 128
      });

      test('getRed returns correct value', () {
        final style = StrokeStyle(color: 0xFFFF0000, thickness: 2.0);
        expect(style.getRed(), 0xFF); // 255
      });

      test('getGreen returns correct value', () {
        final style = StrokeStyle(color: 0xFF00FF00, thickness: 2.0);
        expect(style.getGreen(), 0xFF); // 255
      });

      test('getBlue returns correct value', () {
        final style = StrokeStyle(color: 0xFF0000FF, thickness: 2.0);
        expect(style.getBlue(), 0xFF); // 255
      });

      test('all components extracted correctly from complex color', () {
        final style = StrokeStyle(color: 0xAABBCCDD, thickness: 2.0);

        expect(style.getAlpha(), 0xAA); // 170
        expect(style.getRed(), 0xBB); // 187
        expect(style.getGreen(), 0xCC); // 204
        expect(style.getBlue(), 0xDD); // 221
      });
    });

    group('copyWith', () {
      test('copies with single parameter changed', () {
        final original = StrokeStyle.pen();
        final copied = original.copyWith(color: 0xFFFF0000);

        expect(copied.color, 0xFFFF0000);
        expect(copied.thickness, 2.0); // unchanged
        expect(copied.nibShape, NibShape.circle); // unchanged
      });

      test('copies with multiple parameters changed', () {
        final original = StrokeStyle.pen();
        final copied = original.copyWith(
          color: 0xFFFF0000,
          thickness: 5.0,
          opacity: 0.8,
          nibShape: NibShape.ellipse,
        );

        expect(copied.color, 0xFFFF0000);
        expect(copied.thickness, 5.0);
        expect(copied.opacity, 0.8);
        expect(copied.nibShape, NibShape.ellipse);
        expect(copied.blendMode, DrawingBlendMode.normal); // unchanged
      });

      test('copyWith clamps values', () {
        final original = StrokeStyle.pen();
        final copied = original.copyWith(thickness: 100.0, opacity: 2.0);

        expect(copied.thickness, 50.0);
        expect(copied.opacity, 1.0);
      });
    });

    group('Equality', () {
      test('two styles with same values are equal', () {
        final style1 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          opacity: 1.0,
          nibShape: NibShape.circle,
          blendMode: DrawingBlendMode.normal,
          isEraser: false,
        );

        final style2 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          opacity: 1.0,
          nibShape: NibShape.circle,
          blendMode: DrawingBlendMode.normal,
          isEraser: false,
        );

        expect(style1, equals(style2));
        expect(style1.hashCode, equals(style2.hashCode));
      });

      test('two styles with different color are not equal', () {
        final style1 = StrokeStyle.pen(color: 0xFF000000);
        final style2 = StrokeStyle.pen(color: 0xFFFF0000);

        expect(style1, isNot(equals(style2)));
      });

      test('two styles with different thickness are not equal', () {
        final style1 = StrokeStyle.pen(thickness: 2.0);
        final style2 = StrokeStyle.pen(thickness: 3.0);

        expect(style1, isNot(equals(style2)));
      });

      test('two styles with different nibShape are not equal', () {
        final style1 = StrokeStyle.pen();
        final style2 = StrokeStyle.brush();

        expect(style1, isNot(equals(style2)));
      });
    });

    group('toJson', () {
      test('converts to correct JSON map', () {
        final style = StrokeStyle(
          color: 0xFFFF0000,
          thickness: 5.0,
          opacity: 0.8,
          nibShape: NibShape.ellipse,
          blendMode: DrawingBlendMode.multiply,
          isEraser: false,
        );

        final json = style.toJson();

        expect(json['color'], 0xFFFF0000);
        expect(json['thickness'], 5.0);
        expect(json['opacity'], 0.8);
        expect(json['nibShape'], 'ellipse');
        expect(json['blendMode'], 'multiply');
        expect(json['isEraser'], false);
        // New properties should have defaults
        expect(json['pattern'], 'solid');
        expect(json['texture'], 'none');
        expect(json['glowRadius'], 0.0);
        expect(json['glowIntensity'], 0.0);
        expect(json['dashPattern'], isNull);
      });

      test('converts factory styles correctly', () {
        final penJson = StrokeStyle.pen().toJson();
        expect(penJson['nibShape'], 'circle');

        final highlighterJson = StrokeStyle.highlighter().toJson();
        expect(highlighterJson['nibShape'], 'rectangle');
        expect(highlighterJson['opacity'], 0.5);

        final eraserJson = StrokeStyle.eraser().toJson();
        expect(eraserJson['isEraser'], true);
      });
    });

    group('fromJson', () {
      test('creates from complete JSON map', () {
        final json = {
          'color': 0xFFFF0000,
          'thickness': 5.0,
          'opacity': 0.8,
          'nibShape': 'ellipse',
          'blendMode': 'multiply',
          'isEraser': false,
        };

        final style = StrokeStyle.fromJson(json);

        expect(style.color, 0xFFFF0000);
        expect(style.thickness, 5.0);
        expect(style.opacity, 0.8);
        expect(style.nibShape, NibShape.ellipse);
        expect(style.blendMode, DrawingBlendMode.multiply);
        expect(style.isEraser, false);
      });

      test('creates from minimal JSON with defaults', () {
        final json = {
          'color': 0xFF000000,
          'thickness': 2.0,
        };

        final style = StrokeStyle.fromJson(json);

        expect(style.color, 0xFF000000);
        expect(style.thickness, 2.0);
        expect(style.opacity, 1.0);
        expect(style.nibShape, NibShape.circle);
        expect(style.blendMode, DrawingBlendMode.normal);
        expect(style.isEraser, false);
      });

      test('handles unknown enum values gracefully', () {
        final json = {
          'color': 0xFF000000,
          'thickness': 2.0,
          'nibShape': 'unknown_shape',
          'blendMode': 'unknown_mode',
        };

        final style = StrokeStyle.fromJson(json);

        expect(style.nibShape, NibShape.circle); // fallback
        expect(style.blendMode, DrawingBlendMode.normal); // fallback
      });
    });

    group('JSON roundtrip', () {
      test('toJson and fromJson are inverse operations', () {
        final original = StrokeStyle(
          color: 0xAABBCCDD,
          thickness: 7.5,
          opacity: 0.75,
          nibShape: NibShape.rectangle,
          blendMode: DrawingBlendMode.overlay,
          isEraser: true,
        );

        final json = original.toJson();
        final restored = StrokeStyle.fromJson(json);

        expect(restored, equals(original));
      });

      test('roundtrip works for all factory styles', () {
        final pen = StrokeStyle.pen();
        final highlighter = StrokeStyle.highlighter();
        final brush = StrokeStyle.brush();
        final eraser = StrokeStyle.eraser();

        expect(StrokeStyle.fromJson(pen.toJson()), equals(pen));
        expect(StrokeStyle.fromJson(highlighter.toJson()), equals(highlighter));
        expect(StrokeStyle.fromJson(brush.toJson()), equals(brush));
        expect(StrokeStyle.fromJson(eraser.toJson()), equals(eraser));
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        final style = StrokeStyle.pen();
        final str = style.toString();

        expect(str, contains('StrokeStyle'));
        expect(str, contains('0xFF000000'));
        expect(str, contains('thickness: 2.0'));
        expect(str, contains('nibShape: NibShape.circle'));
      });
    });

    group('New properties (pattern, texture, glow)', () {
      test('creates with default new property values', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
        );

        expect(style.pattern, StrokePattern.solid);
        expect(style.texture, StrokeTexture.none);
        expect(style.glowRadius, 0.0);
        expect(style.glowIntensity, 0.0);
        expect(style.dashPattern, isNull);
      });

      test('creates with pattern', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.dashed,
        );
        expect(style.pattern, StrokePattern.dashed);
      });

      test('creates with texture', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          texture: StrokeTexture.pencil,
        );
        expect(style.texture, StrokeTexture.pencil);
      });

      test('creates with glow properties', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          glowRadius: 5.0,
          glowIntensity: 0.5,
        );
        expect(style.glowRadius, 5.0);
        expect(style.glowIntensity, 0.5);
      });

      test('clamps glow values', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          glowRadius: 50.0, // should clamp to 20
          glowIntensity: 2.0, // should clamp to 1.0
        );
        expect(style.glowRadius, 20.0);
        expect(style.glowIntensity, 1.0);
      });

      test('clamps negative glow values to 0', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          glowRadius: -5.0,
          glowIntensity: -0.5,
        );
        expect(style.glowRadius, 0.0);
        expect(style.glowIntensity, 0.0);
      });

      test('dash pattern is nullable', () {
        final solid = StrokeStyle(color: 0xFF000000, thickness: 2.0);
        final dashed = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          dashPattern: [5.0, 3.0],
        );
        expect(solid.dashPattern, isNull);
        expect(dashed.dashPattern, [5.0, 3.0]);
      });

      test('creates with all new properties', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.dotted,
          texture: StrokeTexture.chalk,
          glowRadius: 10.0,
          glowIntensity: 0.8,
          dashPattern: [2.0, 2.0],
        );

        expect(style.pattern, StrokePattern.dotted);
        expect(style.texture, StrokeTexture.chalk);
        expect(style.glowRadius, 10.0);
        expect(style.glowIntensity, 0.8);
        expect(style.dashPattern, [2.0, 2.0]);
      });
    });

    group('copyWith with new properties', () {
      test('copies with pattern changed', () {
        final original = StrokeStyle.pen();
        final copied = original.copyWith(pattern: StrokePattern.dashed);

        expect(copied.pattern, StrokePattern.dashed);
        expect(copied.texture, StrokeTexture.none); // unchanged
      });

      test('copies with texture changed', () {
        final original = StrokeStyle.pen();
        final copied = original.copyWith(texture: StrokeTexture.pencil);

        expect(copied.texture, StrokeTexture.pencil);
        expect(copied.pattern, StrokePattern.solid); // unchanged
      });

      test('copies with glow properties changed', () {
        final original = StrokeStyle.pen();
        final copied = original.copyWith(
          glowRadius: 8.0,
          glowIntensity: 0.6,
        );

        expect(copied.glowRadius, 8.0);
        expect(copied.glowIntensity, 0.6);
      });

      test('copies with dashPattern changed', () {
        final original = StrokeStyle.pen();
        final copied = original.copyWith(dashPattern: [4.0, 2.0]);

        expect(copied.dashPattern, [4.0, 2.0]);
      });
    });

    group('JSON with new properties', () {
      test('toJson includes new properties', () {
        final style = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.dashed,
          texture: StrokeTexture.pencil,
          glowRadius: 5.0,
          glowIntensity: 0.5,
          dashPattern: [4.0, 2.0],
        );

        final json = style.toJson();

        expect(json['pattern'], 'dashed');
        expect(json['texture'], 'pencil');
        expect(json['glowRadius'], 5.0);
        expect(json['glowIntensity'], 0.5);
        expect(json['dashPattern'], [4.0, 2.0]);
      });

      test('fromJson parses new properties', () {
        final json = {
          'color': 0xFF000000,
          'thickness': 2.0,
          'pattern': 'dotted',
          'texture': 'chalk',
          'glowRadius': 10.0,
          'glowIntensity': 0.8,
          'dashPattern': [2.0, 2.0],
        };

        final style = StrokeStyle.fromJson(json);

        expect(style.pattern, StrokePattern.dotted);
        expect(style.texture, StrokeTexture.chalk);
        expect(style.glowRadius, 10.0);
        expect(style.glowIntensity, 0.8);
        expect(style.dashPattern, [2.0, 2.0]);
      });

      test('fromJson uses defaults for missing new properties', () {
        final json = {
          'color': 0xFF000000,
          'thickness': 2.0,
        };

        final style = StrokeStyle.fromJson(json);

        expect(style.pattern, StrokePattern.solid);
        expect(style.texture, StrokeTexture.none);
        expect(style.glowRadius, 0.0);
        expect(style.glowIntensity, 0.0);
        expect(style.dashPattern, isNull);
      });

      test('fromJson handles unknown enum values for new properties', () {
        final json = {
          'color': 0xFF000000,
          'thickness': 2.0,
          'pattern': 'unknown_pattern',
          'texture': 'unknown_texture',
        };

        final style = StrokeStyle.fromJson(json);

        expect(style.pattern, StrokePattern.solid); // fallback
        expect(style.texture, StrokeTexture.none); // fallback
      });

      test('roundtrip preserves new properties', () {
        final original = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.dashed,
          texture: StrokeTexture.pencil,
          glowRadius: 5.0,
          glowIntensity: 0.5,
          dashPattern: [4.0, 2.0],
        );

        final json = original.toJson();
        final restored = StrokeStyle.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('Equality with new properties', () {
      test('styles with different pattern are not equal', () {
        final style1 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.solid,
        );
        final style2 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.dashed,
        );

        expect(style1, isNot(equals(style2)));
      });

      test('styles with different texture are not equal', () {
        final style1 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          texture: StrokeTexture.none,
        );
        final style2 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          texture: StrokeTexture.pencil,
        );

        expect(style1, isNot(equals(style2)));
      });

      test('styles with different glow are not equal', () {
        final style1 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          glowRadius: 0.0,
        );
        final style2 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          glowRadius: 5.0,
        );

        expect(style1, isNot(equals(style2)));
      });

      test('styles with same new properties are equal', () {
        final style1 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.dashed,
          texture: StrokeTexture.pencil,
          glowRadius: 5.0,
          glowIntensity: 0.5,
          dashPattern: [4.0, 2.0],
        );
        final style2 = StrokeStyle(
          color: 0xFF000000,
          thickness: 2.0,
          pattern: StrokePattern.dashed,
          texture: StrokeTexture.pencil,
          glowRadius: 5.0,
          glowIntensity: 0.5,
          dashPattern: [4.0, 2.0],
        );

        expect(style1, equals(style2));
        expect(style1.hashCode, equals(style2.hashCode));
      });
    });
  });
}
