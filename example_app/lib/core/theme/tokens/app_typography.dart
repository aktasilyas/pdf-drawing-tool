/// StarNote Design System - Typography Tokens
///
/// Tüm metin stilleri bu dosyadan alınmalıdır.
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_typography.dart';
///
/// Text('Başlık', style: AppTypography.headlineLarge)
/// Text('İçerik', style: AppTypography.bodyMedium)
/// ```
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StarNote tipografi stilleri.
///
/// Material Design 3 tipografi sistemine dayalı.
/// Source Serif 4 font ailesi kullanılır.
/// Hardcoded font size kullanımı yasaktır!
abstract class AppTypography {
  // ══════════════════════════════════════════════════════════════════════════
  // DISPLAY - Splash, Hero alanları
  // ══════════════════════════════════════════════════════════════════════════

  /// 32dp - En büyük başlık (Splash ekranı, Hero metinler)
  static TextStyle get displayLarge => GoogleFonts.sourceSerif4(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  /// 28dp - Büyük display metni
  static TextStyle get displayMedium => GoogleFonts.sourceSerif4(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.29,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // HEADLINE - Ekran başlıkları
  // ══════════════════════════════════════════════════════════════════════════

  /// 24dp - Ekran başlığı (AppBar title)
  static TextStyle get headlineLarge => GoogleFonts.sourceSerif4(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// 20dp - Alt ekran başlığı
  static TextStyle get headlineMedium => GoogleFonts.sourceSerif4(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// 18dp - Küçük başlık
  static TextStyle get headlineSmall => GoogleFonts.sourceSerif4(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // TITLE - Card başlıkları, liste başlıkları
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Card/Liste başlığı
  static TextStyle get titleLarge => GoogleFonts.sourceSerif4(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// 14dp - Küçük başlık
  static TextStyle get titleMedium => GoogleFonts.sourceSerif4(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // BODY - Ana içerik metinleri
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Büyük body metni
  static TextStyle get bodyLarge => GoogleFonts.sourceSerif4(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// 14dp - Standart body metni
  static TextStyle get bodyMedium => GoogleFonts.sourceSerif4(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.43,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // LABEL - Butonlar, form label'ları
  // ══════════════════════════════════════════════════════════════════════════

  /// 14dp - Buton metni, form label
  static TextStyle get labelLarge => GoogleFonts.sourceSerif4(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
  );

  /// 12dp - Küçük label
  static TextStyle get labelMedium => GoogleFonts.sourceSerif4(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CAPTION - Yardımcı metinler, tarih/saat
  // ══════════════════════════════════════════════════════════════════════════

  /// 12dp - Caption, yardımcı metin, tarih/saat
  static TextStyle get caption => GoogleFonts.sourceSerif4(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.33,
  );
}
