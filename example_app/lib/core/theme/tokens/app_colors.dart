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
  // BRAND COLORS — Blue Eclipse v2
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana marka rengi — Koyu Lacivert
  static const Color primary = Color(0xFF1B2141);

  /// Primary hover — Biraz açık lacivert
  static const Color primaryLight = Color(0xFF2D3563);

  /// Primary pressed — En koyu
  static const Color primaryDark = Color(0xFF0F1328);

  /// Primary üzerindeki text/icon
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Vurgu rengi — Accent Blue (butonlar, linkler)
  ///
  /// ⚠️ SINIRLI KULLAN! Sadece:
  /// - Slider thumb
  /// - Toggle switch (aktif)
  /// - Star/Favorite icon
  /// - Önemli badge'ler
  static const Color accent = Color(0xFF4A6CF7);

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
  static const Color onWarning = Color(0xFF1B2141);

  /// Hata durumu - Red
  static const Color error = Color(0xFFEF4444);

  /// Error üzerindeki metin/icon rengi
  static const Color onError = Color(0xFFFFFFFF);

  /// Bilgi durumu - Accent Blue
  static const Color info = Color(0xFF4A6CF7);

  /// Info üzerindeki metin/icon rengi
  static const Color onInfo = Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — Beyaz içerik + açık gri background
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — Çok açık soğuk gri
  static const Color backgroundLight = Color(0xFFF4F5F9);

  /// Yüzey — Saf beyaz (card, modal, panel)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Yüzey varyant — Açık gri (search bar, input bg)
  static const Color surfaceVariantLight = Color(0xFFEEEFF5);

  /// Ana metin — Koyu lacivert
  static const Color textPrimaryLight = Color(0xFF1B2141);

  /// İkincil metin — Gri-mavi
  static const Color textSecondaryLight = Color(0xFF8E92A4);

  /// Üçüncül metin — Açık gri
  static const Color textTertiaryLight = Color(0xFFB0B4C3);

  /// Disabled metin
  static const Color textDisabledLight = Color(0xFFCDD0DB);

  /// Border — Çok hafif gri
  static const Color outlineLight = Color(0xFFE2E4ED);

  /// Border varyant
  static const Color outlineVariantLight = Color(0xFFD0D3DE);

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME — Lacivert çerçeve + BEYAZ card'lar!
  // Anahtar: Card/panel/modal BEYAZ kalır, sadece
  // arka plan ve navigation koyu lacivert
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — Koyu lacivert
  static const Color backgroundDark = Color(0xFF0F1328);

  /// Yüzey — BEYAZ! (card, modal, panel hep beyaz)
  static const Color surfaceDark = Color(0xFFFFFFFF);

  /// Yüzey varyant — Lacivert (sidebar, nav, toolbar)
  static const Color surfaceVariantDark = Color(0xFF1B2141);

  /// Ana metin — Koyu lacivert (beyaz card üzerinde)
  static const Color textPrimaryDark = Color(0xFF1B2141);

  /// İkincil metin — Gri-mavi
  static const Color textSecondaryDark = Color(0xFF8E92A4);

  /// Üçüncül metin
  static const Color textTertiaryDark = Color(0xFFB0B4C3);

  /// Disabled metin
  static const Color textDisabledDark = Color(0xFFCDD0DB);

  /// Border — Hafif gri (beyaz card üzerinde)
  static const Color outlineDark = Color(0xFFE2E4ED);

  /// Border varyant
  static const Color outlineVariantDark = Color(0xFF2D3563);

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
