/// Preset color collections for the picker.
import 'package:flutter/material.dart';

/// Preset renk kategorileri
class ColorPresets {
  ColorPresets._();

  /// Açık arka plan için klasik renkler
  static const classicLight = [
    Color(0xFF000000), // Siyah
    Color(0xFFE53935), // Kırmızı
    Color(0xFF1E88E5), // Mavi
    Color(0xFF43A047), // Yeşil
    Color(0xFFFFC107), // Sarı
  ];

  /// Koyu arka plan için klasik renkler
  static const classicDark = [
    Color(0xFFE0E0E0), // Açık gri
    Color(0xFFFFAB91), // Açık turuncu
    Color(0xFFF48FB1), // Açık pembe
    Color(0xFF81D4FA), // Açık mavi
    Color(0xFFFFE082), // Açık sarı
  ];

  /// Highlighter renkleri
  static const highlighter = [
    Color(0xFFFFEB3B), // Sarı
    Color(0xFFFF9800), // Turuncu
    Color(0xFF69F0AE), // Yeşil
    Color(0xFF80D8FF), // Mavi
    Color(0xFFE1BEE7), // Mor
  ];

  /// Tape cream
  static const tapeCream = [
    Color(0xFF80DEEA), // Cyan
    Color(0xFFA5D6A7), // Yeşil
    Color(0xFFF8BBD0), // Pembe
    Color(0xFFFFCC80), // Turuncu
    Color(0xFFFFAB91), // Şeftali
  ];

  /// Tape bright
  static const tapeBright = [
    Color(0xFF40C4FF), // Mavi
    Color(0xFFE040FB), // Mor
    Color(0xFF69F0AE), // Yeşil
    Color(0xFFFFFF00), // Sarı
    Color(0xFFFF6E40), // Turuncu
  ];

  /// Hızlı erişim renkleri
  static const quickAccess = [
    Color(0xFF000000),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFC107),
    Color(0xFF9C27B0),
  ];
}

/// ColorSets - Backward compatibility
class ColorSets {
  ColorSets._();

  static const List<Color> basic = ColorPresets.classicLight;
  static const List<Color> pastel = ColorPresets.tapeCream;
  static const List<Color> neon = ColorPresets.tapeBright;
  static const List<Color> highlighter = ColorPresets.highlighter;
  static const List<Color> quickAccess = ColorPresets.quickAccess;

  static const List<Color> laser = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFFFF00),
    Color(0xFFFF00FF),
  ];

  static Map<String, List<Color>> get all => {
        'Temel': basic,
        'Pastel': pastel,
        'Neon': neon,
      };
}
