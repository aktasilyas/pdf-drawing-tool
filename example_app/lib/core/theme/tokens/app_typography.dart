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

/// StarNote tipografi stilleri.
///
/// Material Design 3 tipografi sistemine dayalı.
/// Hardcoded font size kullanımı yasaktır!
abstract class AppTypography {
  // ══════════════════════════════════════════════════════════════════════════
  // DISPLAY - Splash, Hero alanları
  // ══════════════════════════════════════════════════════════════════════════

  /// 32dp - En büyük başlık (Splash ekranı, Hero metinler)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  /// 28dp - Büyük display metni
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.29,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // HEADLINE - Ekran başlıkları
  // ══════════════════════════════════════════════════════════════════════════

  /// 24dp - Ekran başlığı (AppBar title)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// 20dp - Alt ekran başlığı
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// 18dp - Küçük başlık
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // TITLE - Card başlıkları, liste başlıkları
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Card/Liste başlığı
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// 14dp - Küçük başlık
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // BODY - Ana içerik metinleri
  // ══════════════════════════════════════════════════════════════════════════

  /// 16dp - Büyük body metni
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// 14dp - Standart body metni
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.43,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // LABEL - Butonlar, form label'ları
  // ══════════════════════════════════════════════════════════════════════════

  /// 14dp - Buton metni, form label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
  );

  /// 12dp - Küçük label
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // CAPTION - Yardımcı metinler, tarih/saat
  // ══════════════════════════════════════════════════════════════════════════

  /// 12dp - Caption, yardımcı metin, tarih/saat
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.33,
  );
}
