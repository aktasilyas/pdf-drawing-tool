import 'package:drawing_core/src/models/cover.dart';

/// Original procedural cover family (ids are a persisted contract, never rename).
class CoverFamily {
  CoverFamily._();

  /// Label plate surface; mirrors AppPalette.light.surface in both themes.
  static const int labelPlateColor = 0xFFFBF9F4;

  /// Label plate ink; mirrors AppPalette.light.textPrimary.
  static const int labelInkColor = 0xFF22201C;

  static const linenSage = Cover(
    id: 'linen_sage',
    name: 'Sage Linen',
    style: CoverStyle.material,
    primaryColor: 0xFF8A9A7B,
    material: CoverMaterial.linen,
  );

  static const linenSand = Cover(
    id: 'linen_sand',
    name: 'Sand Linen',
    style: CoverStyle.material,
    primaryColor: 0xFFCDBB98,
    material: CoverMaterial.linen,
  );

  static const linenSlate = Cover(
    id: 'linen_slate',
    name: 'Slate Linen',
    style: CoverStyle.material,
    primaryColor: 0xFF5B6770,
    material: CoverMaterial.linen,
  );

  static const leatherOxblood = Cover(
    id: 'leather_oxblood',
    name: 'Oxblood Leather',
    style: CoverStyle.material,
    primaryColor: 0xFF5E1F24,
    material: CoverMaterial.leather,
  );

  static const leatherCognac = Cover(
    id: 'leather_cognac',
    name: 'Cognac Leather',
    style: CoverStyle.material,
    primaryColor: 0xFF9A5B2E,
    material: CoverMaterial.leather,
  );

  static const leatherNavy = Cover(
    id: 'leather_navy',
    name: 'Navy Leather',
    style: CoverStyle.material,
    primaryColor: 0xFF1F2B44,
    material: CoverMaterial.leather,
  );

  static const kraftNatural = Cover(
    id: 'kraft_natural',
    name: 'Natural Kraft',
    style: CoverStyle.material,
    primaryColor: 0xFFB8946A,
    material: CoverMaterial.kraft,
  );

  static const kraftCharcoal = Cover(
    id: 'kraft_charcoal',
    name: 'Charcoal Kraft',
    style: CoverStyle.material,
    primaryColor: 0xFF3A3836,
    material: CoverMaterial.kraft,
  );

  static const feltMustard = Cover(
    id: 'felt_mustard',
    name: 'Mustard Felt',
    style: CoverStyle.material,
    primaryColor: 0xFFC9A13B,
    material: CoverMaterial.felt,
  );

  static const feltDustyRose = Cover(
    id: 'felt_dusty_rose',
    name: 'Dusty Rose Felt',
    style: CoverStyle.material,
    primaryColor: 0xFFC99A9A,
    material: CoverMaterial.felt,
  );

  static const List<Cover> all = [
    linenSage,
    linenSand,
    linenSlate,
    leatherOxblood,
    leatherCognac,
    leatherNavy,
    kraftNatural,
    kraftCharcoal,
    feltMustard,
    feltDustyRose,
  ];
}
