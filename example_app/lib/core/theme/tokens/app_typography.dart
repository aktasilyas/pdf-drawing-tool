/// ElyaNotes Design System - Typography Tokens
///
/// Source Serif 4: Display, Headline, Title Large (titles, notebook names)
/// Inter: Title Medium/Small, Body, Label (okuma/UI)
///
/// Onay: 3 Mart 2026
library;

import 'package:flutter/material.dart';

/// Uygulama tipografi sistemi.
///
/// M3 type scale'i Source Serif 4 + Inter ile yapılandırır.
/// [create] ile tam TextTheme üretir (ThemeData için).
/// Convenience getter'lar widget'lar içinde doğrudan kullanılabilir.
abstract class AppTypography {
  /// Heading font ailesi
  static const String headingFontFamily = 'SourceSerif4';

  /// Body font ailesi
  static const String bodyFontFamily = 'Inter';

  // ══════════════════════════════════════════════════════════════════════════
  // FULL TEXTTHEME BUILDER — ThemeData'da kullanılır
  // ══════════════════════════════════════════════════════════════════════════

  /// Brightness'a göre tam TextTheme üret
  static TextTheme create(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    final interTheme = base.apply(fontFamily: bodyFontFamily);

    return interTheme.copyWith(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: (base.displaySmall ?? const TextStyle()).copyWith(
        fontFamily: headingFontFamily,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: (base.titleSmall ?? const TextStyle()).copyWith(
        fontFamily: bodyFontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: caption,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: (base.labelSmall ?? const TextStyle()).copyWith(
        fontFamily: bodyFontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DISPLAY — Source Serif 4
  // ══════════════════════════════════════════════════════════════════════════

  /// 32dp - En büyük başlık
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
        letterSpacing: -0.25,
      );

  /// 28dp - Büyük display metni
  static TextStyle get displayMedium => const TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.29,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // HEADLINE — Source Serif 4
  // ══════════════════════════════════════════════════════════════════════════

  /// 24dp - Ekran başlığı
  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
      );

  /// 20dp - Alt ekran başlığı
  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// 18dp - Küçük başlık
  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.44,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // TITLE — titleLarge: Source Serif 4, titleMedium: Inter
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Card/Liste başlığı
  static TextStyle get titleLarge => const TextStyle(
        fontFamily: headingFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  /// 14dp - Küçük başlık
  static TextStyle get titleMedium => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.15,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // BODY — Inter
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Büyük body metni
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.5,
        letterSpacing: 0.5,
      );

  /// 14dp - Standart body metni
  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.43,
        letterSpacing: 0.25,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // LABEL — Inter
  // ══════════════════════════════════════════════════════════════════════════

  /// 14dp - Buton metni, form label
  static TextStyle get labelLarge => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
      );

  /// 12dp - Küçük label
  static TextStyle get labelMedium => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // CAPTION — Inter (M3 bodySmall karşılığı)
  // ══════════════════════════════════════════════════════════════════════════

  /// 12dp - Caption, yardımcı metin, tarih/saat
  static TextStyle get caption => const TextStyle(
        fontFamily: bodyFontFamily,
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
    return TextStyle(
      fontFamily: headingFontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
      color: color,
    );
  }

  /// Not başlığı için özel stil (editor içinde)
  static TextStyle noteTitle({Color? color}) {
    return TextStyle(
      fontFamily: headingFontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      color: color,
    );
  }
}
