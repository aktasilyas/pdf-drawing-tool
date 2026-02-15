/// StarNote Design System - Color Tokens
///
/// Bu dosya tüm uygulama renklerini içerir.
/// Onay tarihi: 1 Şubat 2026
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_colors.dart';
///
/// Container(color: AppColors.primary)
/// ```
library;

import 'package:flutter/material.dart';

/// StarNote renk paleti.
///
/// Tüm renkler bu sınıftan alınmalıdır.
/// Hardcoded renk kullanımı yasaktır!
abstract class AppColors {
  // ══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS — Slate Charcoal
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana marka rengi — Slate
  static const Color primary = Color(0xFF38434F);

  /// Primary hover — Açık slate
  static const Color primaryLight = Color(0xFF4F5B68);

  /// Primary pressed — Koyu charcoal
  static const Color primaryDark = Color(0xFF242930);

  /// Primary üzerindeki text/icon
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Vurgu rengi — Cool Blue (linkler, aktif elementler)
  static const Color accent = Color(0xFF4A8AF7);

  /// Accent üzerindeki text
  static const Color onAccent = Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Başarı durumu - Green
  static const Color success = Color(0xFF4ADE80);

  /// Success üzerindeki metin/icon rengi
  static const Color onSuccess = Color(0xFFFFFFFF);

  /// Uyarı durumu - Yellow
  static const Color warning = Color(0xFFFACC15);

  /// Warning üzerindeki metin/icon rengi
  static const Color onWarning = Color(0xFF1B1F23);

  /// Hata durumu - Red
  static const Color error = Color(0xFFEF4444);

  /// Error üzerindeki metin/icon rengi
  static const Color onError = Color(0xFFFFFFFF);

  /// Bilgi durumu - Cool Blue
  static const Color info = Color(0xFF4A8AF7);

  /// Info üzerindeki metin/icon rengi
  static const Color onInfo = Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — Beyaz içerik + açık gri background
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — Soğuk açık gri
  static const Color backgroundLight = Color(0xFFF2F3F6);

  /// Yüzey — Saf beyaz (card, modal, panel)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Yüzey varyant — Açık gri (search bar, input bg)
  static const Color surfaceVariantLight = Color(0xFFE8EAEF);

  /// Ana metin — Charcoal
  static const Color textPrimaryLight = Color(0xFF1B1F23);

  /// İkincil metin — Slate gri
  static const Color textSecondaryLight = Color(0xFF6B7685);

  /// Üçüncül metin — Açık slate
  static const Color textTertiaryLight = Color(0xFF8D96A1);

  /// Disabled metin
  static const Color textDisabledLight = Color(0xFFB4BAC3);

  /// Border — Açık gri
  static const Color outlineLight = Color(0xFFD6DAE0);

  /// Border varyant
  static const Color outlineVariantLight = Color(0xFFB4BAC3);

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME — Siyah bg + Charcoal header + Slate card
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — Siyah
  static const Color backgroundDark = Color(0xFF000000);

  /// Yüzey — Slate (card, modal, panel)
  static const Color surfaceDark = Color(0xFF38434F);

  /// Yüzey varyant — Charcoal (header, sidebar, toolbar, nav)
  static const Color surfaceVariantDark = Color(0xFF1B1F23);

  /// Dark surface container — Charcoal
  static const Color surfaceContainerDark = Color(0xFF1B1F23);

  /// Dark surface container high — Charcoal+1
  static const Color surfaceContainerHighDark = Color(0xFF242930);

  /// Ana metin — Açık gri (koyu yüzeylerde)
  static const Color textPrimaryDark = Color(0xFFF2F3F6);

  /// İkincil metin — Mist
  static const Color textSecondaryDark = Color(0xFFB4BAC3);

  /// Üçüncül metin — Slate+3
  static const Color textTertiaryDark = Color(0xFF8D96A1);

  /// Disabled metin — Slate+2
  static const Color textDisabledDark = Color(0xFF6B7685);

  /// Border — Slate+1
  static const Color outlineDark = Color(0xFF4F5B68);

  /// Border varyant — Charcoal+2
  static const Color outlineVariantDark = Color(0xFF2E353D);

  // ══════════════════════════════════════════════════════════════════════════
  // PAPER COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Krem/sarı kağıt rengi
  static const Color paperCream = Color(0xFFFFFDE7);

  // ══════════════════════════════════════════════════════════════════════════
  // FOLDER COLORS (12)
  // ══════════════════════════════════════════════════════════════════════════

  /// Klasör renk seçenekleri
  ///
  /// Kullanıcının klasörlerine atayabileceği 12 renk.
  static const List<Color> folderColors = [
    Color(0xFF5B7CFF), // Primary Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFFFB547), // Amber
    Color(0xFF4ADE80), // Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF6B7280), // Gray
    Color(0xFF78716C), // Stone
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // PEN QUICK COLORS (8)
  // ══════════════════════════════════════════════════════════════════════════

  /// Kalem hızlı renk seçenekleri
  ///
  /// Toolbar'da gösterilecek 8 hızlı erişim rengi.
  static const List<Color> penQuickColors = [
    Color(0xFF1B1F2A), // Black
    Color(0xFF6B7280), // Gray
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFFACC15), // Yellow
    Color(0xFF4ADE80), // Green
    Color(0xFF5B7CFF), // Blue
    Color(0xFF8B5CF6), // Purple
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // HIGHLIGHTER COLORS (6)
  // ══════════════════════════════════════════════════════════════════════════

  /// Fosforlu kalem renkleri
  ///
  /// Yarı saydam (50% opacity) highlighter renkleri.
  static const List<Color> highlighterColors = [
    Color(0x80FACC15), // Yellow
    Color(0x804ADE80), // Green
    Color(0x805B7CFF), // Blue
    Color(0x80EC4899), // Pink
    Color(0x808B5CF6), // Purple
    Color(0x80F97316), // Orange
  ];
}
