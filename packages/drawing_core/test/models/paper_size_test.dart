import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PaperSizePreset', () {
    test('has 8 presets', () {
      expect(PaperSizePreset.values.length, 8);
    });
  });

  group('PaperSize', () {
    group('constants', () {
      test('a4 has correct dimensions', () {
        expect(PaperSize.a4.widthMm, 210);
        expect(PaperSize.a4.heightMm, 297);
        expect(PaperSize.a4.preset, PaperSizePreset.a4);
        expect(PaperSize.a4.isLandscape, false);
      });

      test('a5 has correct dimensions', () {
        expect(PaperSize.a5.widthMm, 148);
        expect(PaperSize.a5.heightMm, 210);
        expect(PaperSize.a5.preset, PaperSizePreset.a5);
      });

      test('letter has correct dimensions', () {
        expect(PaperSize.letter.widthMm, 215.9);
        expect(PaperSize.letter.heightMm, 279.4);
        expect(PaperSize.letter.preset, PaperSizePreset.letter);
      });

      test('square has equal dimensions', () {
        expect(PaperSize.square.widthMm, 210);
        expect(PaperSize.square.heightMm, 210);
        expect(PaperSize.square.preset, PaperSizePreset.square);
      });

      test('widescreen is landscape by default', () {
        expect(PaperSize.widescreen.widthMm, 297);
        expect(PaperSize.widescreen.heightMm, 167);
        expect(PaperSize.widescreen.widthMm > PaperSize.widescreen.heightMm, true);
      });
    });

    group('pixel conversion', () {
      test('converts mm to pixels at 72 DPI', () {
        // A4: 210mm x 297mm
        // 210mm * 72 / 25.4 = 595.28 pts
        // 297mm * 72 / 25.4 = 841.89 pts
        expect(PaperSize.a4.widthPx, closeTo(595.28, 0.01));
        expect(PaperSize.a4.heightPx, closeTo(841.89, 0.01));
      });

      test('square has equal pixel dimensions', () {
        expect(PaperSize.square.widthPx, equals(PaperSize.square.heightPx));
      });
    });

    group('aspect ratio', () {
      test('calculates aspect ratio correctly', () {
        expect(PaperSize.a4.aspectRatio, closeTo(210 / 297, 0.001));
        expect(PaperSize.square.aspectRatio, 1.0);
      });
    });

    group('landscape/portrait', () {
      test('landscape property swaps dimensions', () {
        final a4Portrait = PaperSize.a4;
        final a4Landscape = a4Portrait.landscape;

        expect(a4Landscape.widthMm, a4Portrait.heightMm);
        expect(a4Landscape.heightMm, a4Portrait.widthMm);
        expect(a4Landscape.isLandscape, true);
        expect(a4Landscape.preset, PaperSizePreset.a4);
      });

      test('portrait property swaps dimensions back', () {
        final a4Landscape = PaperSize.a4.landscape;
        final a4Portrait = a4Landscape.portrait;

        expect(a4Portrait.widthMm, 210);
        expect(a4Portrait.heightMm, 297);
        expect(a4Portrait.isLandscape, false);
      });

      test('landscape on already landscape returns same', () {
        final landscape1 = PaperSize.a4.landscape;
        final landscape2 = landscape1.landscape;

        expect(landscape2.widthMm, landscape1.widthMm);
        expect(landscape2.heightMm, landscape1.heightMm);
        expect(landscape2.isLandscape, true);
      });

      test('portrait on already portrait returns same', () {
        final portrait1 = PaperSize.a4;
        final portrait2 = portrait1.portrait;

        expect(portrait2.widthMm, portrait1.widthMm);
        expect(portrait2.heightMm, portrait1.heightMm);
        expect(portrait2.isLandscape, false);
      });
    });

    group('fromPreset', () {
      test('returns correct size for each preset', () {
        expect(PaperSize.fromPreset(PaperSizePreset.a4), PaperSize.a4);
        expect(PaperSize.fromPreset(PaperSizePreset.a5), PaperSize.a5);
        expect(PaperSize.fromPreset(PaperSizePreset.a6), PaperSize.a6);
        expect(PaperSize.fromPreset(PaperSizePreset.letter), PaperSize.letter);
        expect(PaperSize.fromPreset(PaperSizePreset.legal), PaperSize.legal);
        expect(PaperSize.fromPreset(PaperSizePreset.square), PaperSize.square);
        expect(PaperSize.fromPreset(PaperSizePreset.widescreen), PaperSize.widescreen);
      });

      test('returns a4 for custom preset', () {
        expect(PaperSize.fromPreset(PaperSizePreset.custom), PaperSize.a4);
      });
    });

    group('JSON serialization', () {
      test('toJson includes all properties', () {
        final json = PaperSize.a4.toJson();

        expect(json['widthMm'], 210);
        expect(json['heightMm'], 297);
        expect(json['preset'], 'a4');
        expect(json['isLandscape'], false);
      });

      test('fromJson parses all properties', () {
        final json = {
          'widthMm': 210.0,
          'heightMm': 297.0,
          'preset': 'a4',
          'isLandscape': false,
        };

        final paperSize = PaperSize.fromJson(json);

        expect(paperSize.widthMm, 210);
        expect(paperSize.heightMm, 297);
        expect(paperSize.preset, PaperSizePreset.a4);
        expect(paperSize.isLandscape, false);
      });

      test('fromJson handles int values', () {
        final json = {
          'widthMm': 210,
          'heightMm': 297,
          'preset': 'a5',
          'isLandscape': true,
        };

        final paperSize = PaperSize.fromJson(json);

        expect(paperSize.widthMm, 210);
        expect(paperSize.heightMm, 297);
        expect(paperSize.isLandscape, true);
      });

      test('fromJson handles unknown preset', () {
        final json = {
          'widthMm': 200.0,
          'heightMm': 300.0,
          'preset': 'unknown_preset',
        };

        final paperSize = PaperSize.fromJson(json);

        expect(paperSize.preset, PaperSizePreset.custom);
      });

      test('fromJson defaults isLandscape to false', () {
        final json = {
          'widthMm': 210.0,
          'heightMm': 297.0,
          'preset': 'a4',
        };

        final paperSize = PaperSize.fromJson(json);

        expect(paperSize.isLandscape, false);
      });

      test('roundtrip preserves data', () {
        final original = PaperSize.a4.landscape;
        final json = original.toJson();
        final restored = PaperSize.fromJson(json);

        expect(restored.widthMm, original.widthMm);
        expect(restored.heightMm, original.heightMm);
        expect(restored.preset, original.preset);
        expect(restored.isLandscape, original.isLandscape);
      });
    });

    group('equality', () {
      test('same dimensions are equal', () {
        final size1 = PaperSize(
          widthMm: 210,
          heightMm: 297,
          preset: PaperSizePreset.a4,
        );
        final size2 = PaperSize(
          widthMm: 210,
          heightMm: 297,
          preset: PaperSizePreset.a4,
        );

        expect(size1, equals(size2));
        expect(size1.hashCode, equals(size2.hashCode));
      });

      test('different dimensions are not equal', () {
        expect(PaperSize.a4, isNot(equals(PaperSize.a5)));
      });

      test('different orientation are not equal', () {
        expect(PaperSize.a4, isNot(equals(PaperSize.a4.landscape)));
      });

      test('preset does not affect equality', () {
        // Same physical dimensions, different preset
        final size1 = PaperSize(
          widthMm: 210,
          heightMm: 297,
          preset: PaperSizePreset.a4,
        );
        final size2 = PaperSize(
          widthMm: 210,
          heightMm: 297,
          preset: PaperSizePreset.custom,
        );

        expect(size1, equals(size2));
      });
    });

    group('toPageSize extension', () {
      test('converts to PageSize with correct pixel dimensions', () {
        final paperSize = PaperSize.a4;
        final pageSize = paperSize.toPageSize();

        expect(pageSize.width, closeTo(595.28, 0.01));
        expect(pageSize.height, closeTo(841.89, 0.01));
      });

      test('converts landscape correctly', () {
        final paperSize = PaperSize.a4.landscape;
        final pageSize = paperSize.toPageSize();

        expect(pageSize.width, closeTo(841.89, 0.01));
        expect(pageSize.height, closeTo(595.28, 0.01));
      });

      test('converts custom size correctly', () {
        final paperSize = PaperSize(
          widthMm: 100,
          heightMm: 200,
          preset: PaperSizePreset.custom,
        );
        final pageSize = paperSize.toPageSize();

        expect(pageSize.width, closeTo(100 * 72 / 25.4, 0.01));
        expect(pageSize.height, closeTo(200 * 72 / 25.4, 0.01));
      });
    });
  });
}
