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
  // BRAND COLORS — Blue Eclipse
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana marka rengi - Midnight Indigo
  static const Color primary = Color(0xFF505081);

  /// Primary hover state - Lavanta
  static const Color primaryLight = Color(0xFF8686AC);

  /// Primary pressed state - Koyu lacivert
  static const Color primaryDark = Color(0xFF272757);

  /// Primary üzerindeki metin/icon rengi
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Vurgu rengi - Amber Gold
  ///
  /// ⚠️ SINIRLI KULLAN! Sadece:
  /// - Slider thumb
  /// - Toggle switch (aktif)
  /// - Star/Favorite icon
  /// - Önemli badge'ler
  static const Color accent = Color(0xFFFFB547);

  /// Accent üzerindeki metin/icon rengi
  static const Color onAccent = Color(0xFF0F0E47);

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
  static const Color onWarning = Color(0xFF0F0E47);

  /// Hata durumu - Red
  static const Color error = Color(0xFFEF4444);

  /// Error üzerindeki metin/icon rengi
  static const Color onError = Color(0xFFFFFFFF);

  /// Bilgi durumu - Primary ile aynı
  static const Color info = Color(0xFF505081);

  /// Info üzerindeki metin/icon rengi
  static const Color onInfo = Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — Beyaz + lacivertin açık tonları
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — çok açık lavanta-gri
  static const Color backgroundLight = Color(0xFFF0F1F8);

  /// Yüzey — saf beyaz (card, modal, panel)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Yüzey varyant — açık lavanta
  static const Color surfaceVariantLight = Color(0xFFE8E9F3);

  /// Ana metin — en koyu lacivert
  static const Color textPrimaryLight = Color(0xFF0F0E47);

  /// İkincil metin — orta lacivert
  static const Color textSecondaryLight = Color(0xFF505081);

  /// Üçüncül metin — açık lavanta
  static const Color textTertiaryLight = Color(0xFF8686AC);

  /// Disabled metin
  static const Color textDisabledLight = Color(0xFFB8B9D0);

  /// Border — açık lacivert
  static const Color outlineLight = Color(0xFFD0D1E3);

  /// Border varyant
  static const Color outlineVariantLight = Color(0xFFB8B9D0);

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME — Lacivert tonları, SİYAH YOK!
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — en koyu lacivert (#121212 DEĞİL!)
  static const Color backgroundDark = Color(0xFF0F0E47);

  /// Yüzey — koyu lacivert (card, modal)
  static const Color surfaceDark = Color(0xFF1A1954);

  /// Yüzey varyant — orta-koyu lacivert
  static const Color surfaceVariantDark = Color(0xFF272757);

  /// Ana metin — beyazımsı lavanta
  static const Color textPrimaryDark = Color(0xFFF0F1F8);

  /// İkincil metin — açık lavanta
  static const Color textSecondaryDark = Color(0xFF8686AC);

  /// Üçüncül metin — soluk lavanta
  static const Color textTertiaryDark = Color(0xFF6A6A94);

  /// Disabled metin
  static const Color textDisabledDark = Color(0xFF4A4A70);

  /// Border — lacivert border
  static const Color outlineDark = Color(0xFF3A3970);

  /// Border varyant
  static const Color outlineVariantDark = Color(0xFF4A4A7A);

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
