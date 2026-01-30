import 'package:drawing_core/src/models/cover.dart';

/// Kapak kayıt defteri - tüm kapak tanımları
class CoverRegistry {
  CoverRegistry._();

  // === SOLID KAPAKLAR (Düz Renk) ===
  static const solidBlack = Cover(
    id: 'solid_black',
    name: 'Klasik Siyah',
    style: CoverStyle.solid,
    primaryColor: 0xFF1A1A1A,
  );

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
  static const minimalWhite = Cover(
    id: 'minimal_white',
    name: 'Beyaz Çerçeve',
    style: CoverStyle.minimal,
    primaryColor: 0xFFFFFFFF,
  );

  static const minimalBlack = Cover(
    id: 'minimal_black',
    name: 'Siyah Çerçeve',
    style: CoverStyle.minimal,
    primaryColor: 0xFF1A1A1A,
  );

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

  // === TÜM KAPAKLAR ===
  static const List<Cover> all = [
    solidBlack,
    solidNavy,
    solidBurgundy,
    minimalWhite,
    minimalBlack,
    minimalGray,
    patternDots,
    patternLines,
    gradientSunset,
    gradientOcean,
    gradientForest,
    gradientPurple,
  ];

  static const List<Cover> free = [
    solidBlack,
    solidNavy,
    solidBurgundy,
    minimalWhite,
    minimalBlack,
    minimalGray,
    patternDots,
    patternLines,
  ];

  static const List<Cover> premium = [
    gradientSunset,
    gradientOcean,
    gradientForest,
    gradientPurple,
  ];

  /// Default kapak
  static const Cover defaultCover = solidBlack;

  /// ID'ye göre kapak bul
  static Cover? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
