import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cover JSON', () {
    test('round-trips a material cover', () {
      const cover = Cover(
        id: 'leather_navy',
        name: 'Navy Leather',
        style: CoverStyle.material,
        primaryColor: 0xFF1F2B44,
        material: CoverMaterial.leather,
      );
      final decoded = Cover.fromJson(cover.toJson());
      expect(decoded.id, 'leather_navy');
      expect(decoded.style, CoverStyle.material);
      expect(decoded.material, CoverMaterial.leather);
      expect(decoded.primaryColor, 0xFF1F2B44);
    });

    test('legacy JSON without material decodes with null material', () {
      final cover = Cover.fromJson({
        'id': 'solid_navy',
        'name': 'Navy',
        'style': 'solid',
        'primaryColor': 0xFF1E3A5F,
      });
      expect(cover.material, isNull);
      expect(cover.toJson().containsKey('material'), isFalse);
    });

    test('unknown style falls back to solid', () {
      final cover = Cover.fromJson({
        'id': 'x',
        'name': 'X',
        'style': 'hologram',
        'primaryColor': 1,
      });
      expect(cover.style, CoverStyle.solid);
    });

    test('unknown material falls back to null', () {
      final cover = Cover.fromJson({
        'id': 'x',
        'name': 'X',
        'style': 'material',
        'primaryColor': 1,
        'material': 'velvet',
      });
      expect(cover.material, isNull);
    });
  });
}
