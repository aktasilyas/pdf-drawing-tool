import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_pen_toolbar/flutter_pen_toolbar.dart' as toolbar;
import 'package:drawing_ui/src/utils/pen_type_mapper.dart';

void main() {
  group('PenTypeMapper', () {
    group('toToolbarPenType', () {
      test('maps pencil correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.pencil),
          toolbar.PenType.pencil,
        );
      });

      test('maps hardPencil to pencilTip', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.hardPencil),
          toolbar.PenType.pencilTip,
        );
      });

      test('maps ballpointPen correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.ballpointPen),
          toolbar.PenType.ballpointPen,
        );
      });

      test('maps gelPen correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.gelPen),
          toolbar.PenType.gelPen,
        );
      });

      test('maps dashedPen correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.dashedPen),
          toolbar.PenType.dashedPen,
        );
      });

      test('maps highlighter correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.highlighter),
          toolbar.PenType.highlighter,
        );
      });

      test('maps brushPen correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.brushPen),
          toolbar.PenType.brushPen,
        );
      });

      test('maps neonHighlighter correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.neonHighlighter),
          toolbar.PenType.neonHighlighter,
        );
      });

      test('maps rulerPen correctly', () {
        expect(
          PenTypeMapper.toToolbarPenType(PenType.rulerPen),
          toolbar.PenType.rulerPen,
        );
      });
    });

    group('fromToolbarPenType', () {
      test('maps pencil correctly', () {
        expect(
          PenTypeMapper.fromToolbarPenType(toolbar.PenType.pencil),
          PenType.pencil,
        );
      });

      test('maps pencilTip to hardPencil', () {
        expect(
          PenTypeMapper.fromToolbarPenType(toolbar.PenType.pencilTip),
          PenType.hardPencil,
        );
      });

      test('maps ballpointPen correctly', () {
        expect(
          PenTypeMapper.fromToolbarPenType(toolbar.PenType.ballpointPen),
          PenType.ballpointPen,
        );
      });

      test('maps unsupported types to ballpointPen fallback', () {
        expect(
          PenTypeMapper.fromToolbarPenType(toolbar.PenType.marker),
          PenType.ballpointPen,
        );
        expect(
          PenTypeMapper.fromToolbarPenType(toolbar.PenType.fountainPen),
          PenType.ballpointPen,
        );
      });
    });

    group('isSupported', () {
      test('returns true for supported types', () {
        expect(PenTypeMapper.isSupported(toolbar.PenType.pencil), isTrue);
        expect(PenTypeMapper.isSupported(toolbar.PenType.pencilTip), isTrue);
        expect(PenTypeMapper.isSupported(toolbar.PenType.ballpointPen), isTrue);
        expect(PenTypeMapper.isSupported(toolbar.PenType.rulerPen), isTrue);
      });

      test('returns false for unsupported types', () {
        expect(PenTypeMapper.isSupported(toolbar.PenType.marker), isFalse);
        expect(PenTypeMapper.isSupported(toolbar.PenType.fountainPen), isFalse);
        expect(PenTypeMapper.isSupported(toolbar.PenType.fineliner), isFalse);
        expect(PenTypeMapper.isSupported(toolbar.PenType.crayon), isFalse);
      });
    });

    group('Round-trip conversion', () {
      test('all supported pen types round-trip correctly', () {
        for (final penType in PenType.values) {
          final toolbarType = PenTypeMapper.toToolbarPenType(penType);
          final backToPenType = PenTypeMapper.fromToolbarPenType(toolbarType);
          expect(backToPenType, penType,
              reason: 'Round-trip failed for $penType');
        }
      });
    });
  });
}
