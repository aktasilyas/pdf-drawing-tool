/// ElyaNotes Design System - Typography Tokens
///
/// Plus Jakarta Sans: Display, Headline, Title Large (branding/headings)
/// Inter: Title Medium/Small, Body, Label (okuma/UI)
///
/// Onay: 3 Mart 2026
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulama tipografi sistemi.
///
/// M3 type scale'i Plus Jakarta Sans + Inter ile yapılandırır.
/// [create] ile tam TextTheme üretir (ThemeData için).
/// Convenience getter'lar widget'lar içinde doğrudan kullanılabilir.
abstract class AppTypography {
  /// Heading font ailesi
  static String get headingFontFamily => 'Plus Jakarta Sans';

  /// Body font ailesi
  static String get bodyFontFamily => 'Inter';

  // ══════════════════════════════════════════════════════════════════════════
  // FULL TEXTTHEME BUILDER — ThemeData'da kullanılır
  // ══════════════════════════════════════════════════════════════════════════

  /// Brightness'a göre tam TextTheme üret
  static TextTheme create(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    final interTheme = GoogleFonts.interTextTheme(base);

    return interTheme.copyWith(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: GoogleFonts.plusJakartaSans(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: GoogleFonts.inter(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: caption,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: GoogleFonts.inter(
        textStyle: base.labelSmall,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DISPLAY — Plus Jakarta Sans
  // ══════════════════════════════════════════════════════════════════════════

  /// 32dp - En büyük başlık
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
        letterSpacing: -0.25,
      );

  /// 28dp - Büyük display metni
  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.29,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // HEADLINE — Plus Jakarta Sans
  // ══════════════════════════════════════════════════════════════════════════

  /// 24dp - Ekran başlığı
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
      );

  /// 20dp - Alt ekran başlığı
  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// 18dp - Küçük başlık
  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.44,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // TITLE — titleLarge: Plus Jakarta Sans, titleMedium: Inter
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Card/Liste başlığı
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  /// 14dp - Küçük başlık
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.15,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // BODY — Inter
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Büyük body metni
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.5,
        letterSpacing: 0.5,
      );

  /// 14dp - Standart body metni
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.43,
        letterSpacing: 0.25,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // LABEL — Inter
  // ══════════════════════════════════════════════════════════════════════════

  /// 14dp - Buton metni, form label
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
      );

  /// 12dp - Küçük label
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // CAPTION — Inter (M3 bodySmall karşılığı)
  // ══════════════════════════════════════════════════════════════════════════

  /// 12dp - Caption, yardımcı metin, tarih/saat
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.33,
        letterSpacing: 0.4,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // SPECIAL STYLES
  // ══════════════════════════════════════════════════════════════════════════

  /// Logo/branding için özel stil
  static TextStyle logo({double fontSize = 24, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
      color: color,
    );
  }

  /// Not başlığı için özel stil (editor içinde)
  static TextStyle noteTitle({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      color: color,
    );
  }
}
