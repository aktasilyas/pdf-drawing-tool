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
  // BRAND COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana marka rengi - Light Indigo / Creative Blue
  static const Color primary = Color(0xFF5B7CFF);

  /// Primary hover state
  static const Color primaryLight = Color(0xFF7B96FF);

  /// Primary pressed state
  static const Color primaryDark = Color(0xFF4A68E0);

  /// Primary üzerindeki metin/icon rengi
  static const Color onPrimary = Colors.white;

  /// Vurgu rengi - Amber Gold
  ///
  /// ⚠️ SINIRLI KULLAN! Sadece:
  /// - Slider thumb
  /// - Toggle switch (aktif)
  /// - Star/Favorite icon
  /// - Önemli badge'ler
  static const Color accent = Color(0xFFFFB547);

  /// Accent üzerindeki metin/icon rengi
  static const Color onAccent = Color(0xFF1B1F2A);

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Başarı durumu - Green
  static const Color success = Color(0xFF4ADE80);

  /// Success üzerindeki metin/icon rengi
  static const Color onSuccess = Colors.white;

  /// Uyarı durumu - Yellow
  static const Color warning = Color(0xFFFACC15);

  /// Warning üzerindeki metin/icon rengi
  static const Color onWarning = Color(0xFF1B1F2A);

  /// Hata durumu - Red
  static const Color error = Color(0xFFEF4444);

  /// Error üzerindeki metin/icon rengi
  static const Color onError = Colors.white;

  /// Bilgi durumu - Primary ile aynı
  static const Color info = Color(0xFF5B7CFF);

  /// Info üzerindeki metin/icon rengi
  static const Color onInfo = Colors.white;

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Light tema arkaplan - Soft blue-gray (göz yormaz)
  static const Color backgroundLight = Color(0xFFF5F7FB);

  /// Light tema surface - Cards, modals
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Light tema surface variant - Alternatif yüzey
  static const Color surfaceVariantLight = Color(0xFFF0F2F5);

  /// Light tema ana metin rengi
  static const Color textPrimaryLight = Color(0xFF1B1F2A);

  /// Light tema ikincil metin rengi
  static const Color textSecondaryLight = Color(0xFF6B7280);

  /// Light tema üçüncül metin rengi
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  /// Light tema disabled metin rengi
  static const Color textDisabledLight = Color(0xFFD1D5DB);

  /// Light tema border/divider rengi
  static const Color outlineLight = Color(0xFFE5E7EB);

  /// Light tema alternatif border rengi
  static const Color outlineVariantLight = Color(0xFFD1D5DB);

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Dark tema arkaplan - OLED friendly
  static const Color backgroundDark = Color(0xFF121212);

  /// Dark tema surface - Cards, modals
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Dark tema surface variant - Alternatif yüzey
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);

  /// Dark tema ana metin rengi
  static const Color textPrimaryDark = Color(0xFFF4F4F4);

  /// Dark tema ikincil metin rengi
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  /// Dark tema üçüncül metin rengi
  static const Color textTertiaryDark = Color(0xFF6B7280);

  /// Dark tema disabled metin rengi
  static const Color textDisabledDark = Color(0xFF4B5563);

  /// Dark tema border/divider rengi
  static const Color outlineDark = Color(0xFF2C2C2C);

  /// Dark tema alternatif border rengi
  static const Color outlineVariantDark = Color(0xFF404040);

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
