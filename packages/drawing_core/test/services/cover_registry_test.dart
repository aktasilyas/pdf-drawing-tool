import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

/// Persisted ids are a contract: none of these may ever disappear.
const _legacyIds = [
  'solid_navy',
  'solid_burgundy',
  'minimal_gray',
  'pattern_dots',
  'pattern_lines',
  'gradient_sunset',
  'gradient_ocean',
  'gradient_forest',
  'gradient_purple',
  'img_kraft',
  'img_geometric',
  'img_terrazzo',
  'img_dinosaur',
  'img_space',
  'img_floral',
  'img_navy_gold',
  'img_leather',
];

const _familyIds = [
  'linen_sage',
  'linen_sand',
  'linen_slate',
  'leather_oxblood',
  'leather_cognac',
  'leather_navy',
  'kraft_natural',
  'kraft_charcoal',
  'felt_mustard',
  'felt_dusty_rose',
];

void main() {
  group('CoverRegistry', () {
    test('every legacy and family id resolves via byId', () {
      for (final id in [..._legacyIds, ..._familyIds]) {
        expect(CoverRegistry.byId(id), isNotNull, reason: id);
        expect(CoverRegistry.byId(id)!.id, id);
      }
    });

    test('pickable is the 10 family ids in BRIEF order', () {
      expect(CoverRegistry.pickable.map((c) => c.id), _familyIds);
      expect(CoverRegistry.family, CoverRegistry.pickable);
    });

    test('family covers are material style, free, with a material', () {
      for (final c in CoverRegistry.family) {
        expect(c.style, CoverStyle.material, reason: c.id);
        expect(c.material, isNotNull, reason: c.id);
        expect(c.isPremium, isFalse, reason: c.id);
      }
    });

    test('default cover is linen_sage', () {
      expect(CoverRegistry.defaultCover.id, 'linen_sage');
      expect(CoverRegistry.defaultCover, CoverFamily.linenSage);
    });

    test('ids are unique and all = legacy + family', () {
      final ids = CoverRegistry.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.length, _legacyIds.length + _familyIds.length);
    });

    test('label plate constants', () {
      expect(CoverFamily.labelPlateColor, 0xFFFBF9F4);
      expect(CoverFamily.labelInkColor, isA<int>());
    });
  });
}
