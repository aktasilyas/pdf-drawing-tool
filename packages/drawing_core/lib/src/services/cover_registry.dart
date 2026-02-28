import 'package:drawing_core/src/models/cover.dart';

/// Kapak kayıt defteri - tüm kapak tanımları
class CoverRegistry {
  CoverRegistry._();

  // === SOLID KAPAKLAR (Düz Renk) ===
  static const solidNavy = Cover(
    id: 'solid_navy',
    name: 'Lacivert',
    style: CoverStyle.solid,
    primaryColor: 0xFF1E3A5F,
  );

  static const solidBurgundy = Cover(
    id: 'solid_burgundy',
    name: 'Bordo',
    style: CoverStyle.solid,
    primaryColor: 0xFF722F37,
  );

  // === MINIMAL KAPAKLAR (Çerçeveli) ===
  static const minimalGray = Cover(
    id: 'minimal_gray',
    name: 'Gri Çerçeve',
    style: CoverStyle.minimal,
    primaryColor: 0xFF607D8B,
  );

  // === PATTERN KAPAKLAR (Desenli) ===
  static const patternDots = Cover(
    id: 'pattern_dots',
    name: 'Noktalı',
    style: CoverStyle.pattern,
    primaryColor: 0xFF424242,
  );

  static const patternLines = Cover(
    id: 'pattern_lines',
    name: 'Çizgili',
    style: CoverStyle.pattern,
    primaryColor: 0xFF37474F,
  );

  // === GRADIENT KAPAKLAR (Premium) ===
  static const gradientSunset = Cover(
    id: 'gradient_sunset',
    name: 'Gün Batımı',
    style: CoverStyle.gradient,
    primaryColor: 0xFFFF6B6B,
    secondaryColor: 0xFFFFE66D,
    isPremium: true,
  );

  static const gradientOcean = Cover(
    id: 'gradient_ocean',
    name: 'Okyanus',
    style: CoverStyle.gradient,
    primaryColor: 0xFF667EEA,
    secondaryColor: 0xFF64B5F6,
    isPremium: true,
  );

  static const gradientForest = Cover(
    id: 'gradient_forest',
    name: 'Orman',
    style: CoverStyle.gradient,
    primaryColor: 0xFF11998E,
    secondaryColor: 0xFF38EF7D,
    isPremium: true,
  );

  static const gradientPurple = Cover(
    id: 'gradient_purple',
    name: 'Lavanta',
    style: CoverStyle.gradient,
    primaryColor: 0xFF8E2DE2,
    secondaryColor: 0xFF4A00E0,
    isPremium: true,
  );

  // === GÖRSEL KAPAKLAR (Image) ===
  static const imageCoverKraft = Cover(
    id: 'img_kraft',
    name: 'Kraft',
    style: CoverStyle.image,
    primaryColor: 0xFFD2B48C,
    imagePath: 'assets/covers/cover_01_kraft.webp',
  );

  static const imageCoverGeometric = Cover(
    id: 'img_geometric',
    name: 'Geometrik',
    style: CoverStyle.image,
    primaryColor: 0xFFFFFFFF,
    imagePath: 'assets/covers/cover_02_geometric_bw.png',
  );

  static const imageCoverTerrazzo = Cover(
    id: 'img_terrazzo',
    name: 'Terrazzo',
    style: CoverStyle.image,
    primaryColor: 0xFFF0ECEA,
    imagePath: 'assets/covers/cover_03_terrazzo.png',
  );

  static const imageCoverDinosaur = Cover(
    id: 'img_dinosaur',
    name: 'Dinozor',
    style: CoverStyle.image,
    primaryColor: 0xFFFDE68A,
    imagePath: 'assets/covers/cover_06_dinosaur.webp',
  );

  static const imageCoverSpace = Cover(
    id: 'img_space',
    name: 'Uzay',
    style: CoverStyle.image,
    primaryColor: 0xFF0C2340,
    imagePath: 'assets/covers/cover_07_space.webp',
  );

  static const imageCoverFloral = Cover(
    id: 'img_floral',
    name: 'Çiçekli',
    style: CoverStyle.image,
    primaryColor: 0xFFE91E8C,
    imagePath: 'assets/covers/cover_08_floral_pink.webp',
    isPremium: true,
  );

  static const imageCoverNavyGold = Cover(
    id: 'img_navy_gold',
    name: 'Lacivert Gold',
    style: CoverStyle.image,
    primaryColor: 0xFF1B2A4A,
    imagePath: 'assets/covers/cover_09_navy_gold.webp',
    isPremium: true,
  );

  static const imageCoverLeather = Cover(
    id: 'img_leather',
    name: 'Deri',
    style: CoverStyle.image,
    primaryColor: 0xFF3E2723,
    imagePath: 'assets/covers/cover_10_leather.webp',
    isPremium: true,
  );

  // === TÜM KAPAKLAR ===
  static const List<Cover> all = [
    solidNavy,
    solidBurgundy,
    minimalGray,
    patternDots,
    patternLines,
    gradientSunset,
    gradientOcean,
    gradientForest,
    gradientPurple,
    imageCoverKraft,
    imageCoverGeometric,
    imageCoverTerrazzo,
    imageCoverDinosaur,
    imageCoverSpace,
    imageCoverFloral,
    imageCoverNavyGold,
    imageCoverLeather,
  ];

  static const List<Cover> free = [
    solidNavy,
    solidBurgundy,
    minimalGray,
    patternDots,
    patternLines,
    imageCoverKraft,
    imageCoverGeometric,
    imageCoverTerrazzo,
    imageCoverDinosaur,
    imageCoverSpace,
  ];

  static const List<Cover> premium = [
    gradientSunset,
    gradientOcean,
    gradientForest,
    gradientPurple,
    imageCoverFloral,
    imageCoverNavyGold,
    imageCoverLeather,
  ];

  /// Default kapak
  static const Cover defaultCover = solidNavy;

  /// ID'ye göre kapak bul
  static Cover? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
