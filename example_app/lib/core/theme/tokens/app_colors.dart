/// ElyaNotes Design System - Color Tokens
///
/// #00B988 (Emerald Green) bazlı M3 renk paleti.
/// Onay tarihi: 3 Mart 2026
///
/// Kullanım:
/// ```dart
/// import 'package:example_app/core/theme/tokens/app_colors.dart';
/// Container(color: AppColors.primary)
/// ```
library;

import 'package:flutter/material.dart';

/// ElyaNotes renk paleti — #00B988 Emerald Green
///
/// Tüm renkler bu sınıftan alınmalıdır.
/// Hardcoded renk kullanımı yasaktır!
abstract class AppColors {
  // ══════════════════════════════════════════════════════════════════════════
  // SEED COLOR
  // ══════════════════════════════════════════════════════════════════════════

  /// Marka seed rengi — UI'da doğrudan kullanılmaz, referans amaçlı
  static const Color seed = Color(0xFF00B988);

  // ══════════════════════════════════════════════════════════════════════════
  // BRAND COLORS — Emerald Green
  // ══════════════════════════════════════════════════════════════════════════

  /// Ana marka rengi — M3 accessible primary (light mode)
  /// #00B988 seed'den türetilmiş, WCAG AA uyumlu (beyaz üzerinde 6.8:1)
  static const Color primary = Color(0xFF006B53);

  /// Primary hover — Açık emerald
  static const Color primaryLight = Color(0xFF7DF7CC);

  /// Primary pressed — Koyu emerald
  static const Color primaryDark = Color(0xFF005140);

  /// Primary üzerindeki text/icon
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Primary container — Soft mint (chips, selection bg)
  static const Color primaryContainer = Color(0xFF7DF7CC);

  /// Primary container üzerindeki text
  static const Color onPrimaryContainer = Color(0xFF002018);

  /// Dark mode primary — Parlak emerald
  static const Color primaryDarkMode = Color(0xFF5FDAB1);

  /// Dark mode onPrimary
  static const Color onPrimaryDarkMode = Color(0xFF003829);

  /// Dark mode primary container
  static const Color primaryContainerDarkMode = Color(0xFF005140);

  /// Dark mode onPrimaryContainer
  static const Color onPrimaryContainerDarkMode = Color(0xFF7DF7CC);

  /// Vurgu rengi — Soft Blue (tertiary, tags, kategoriler)
  static const Color accent = Color(0xFF535F79);

  /// Accent üzerindeki text
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Accent container — Soft blue
  static const Color accentContainer = Color(0xFFD7E3FF);

  /// Accent container üzerindeki text
  static const Color onAccentContainer = Color(0xFF0F1B30);

  // ══════════════════════════════════════════════════════════════════════════
  // SECONDARY — Desaturated green-gray
  // ══════════════════════════════════════════════════════════════════════════

  static const Color secondary = Color(0xFF506459);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD3E8DC);
  static const Color onSecondaryContainer = Color(0xFF0E1F17);

  static const Color secondaryDarkMode = Color(0xFFB7CCC0);
  static const Color onSecondaryDarkMode = Color(0xFF233530);
  static const Color secondaryContainerDarkMode = Color(0xFF394C42);
  static const Color onSecondaryContainerDarkMode = Color(0xFFD3E8DC);

  // ══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Başarı durumu - Green
  static const Color success = Color(0xFF4ADE80);
  static const Color onSuccess = Color(0xFFFFFFFF);

  /// Uyarı durumu - Yellow
  static const Color warning = Color(0xFFFACC15);
  static const Color onWarning = Color(0xFF1B1F23);

  /// Hata durumu - Red
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  /// Bilgi durumu — Primary ile aynı
  static const Color info = Color(0xFF006B53);
  static const Color onInfo = Color(0xFFFFFFFF);

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME — Green-tinted neutrals
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — Saf beyaz
  static const Color backgroundLight = Color(0xFFFFFFFF);

  /// Yüzey — Beyaz (card, modal, panel)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Yüzey varyant — Hafif yeşil tint
  static const Color surfaceVariantLight = Color(0xFFE3EBE5);

  /// Surface container lowest
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);

  /// Surface container low — Card'lar
  static const Color surfaceContainerLowLight = Color(0xFFEEF6F0);

  /// Surface container — Navigation bar
  static const Color surfaceContainerLight = Color(0xFFE9F1EB);

  /// Surface container high — Search bar, elevated
  static const Color surfaceContainerHighLight = Color(0xFFE3EBE5);

  /// Surface container highest — Text field
  static const Color surfaceContainerHighestLight = Color(0xFFDDE5DF);

  /// Ana metin — Koyu yeşil-siyah
  static const Color textPrimaryLight = Color(0xFF161D19);

  /// İkincil metin — Orta yeşil-gri
  static const Color textSecondaryLight = Color(0xFF3E4943);

  /// Üçüncül metin
  static const Color textTertiaryLight = Color(0xFF6F7A74);

  /// Disabled metin
  static const Color textDisabledLight = Color(0xFFBECAC3);

  /// Border — Yeşil-gri
  static const Color outlineLight = Color(0xFF6F7A74);

  /// Border varyant — Açık yeşil-gri
  static const Color outlineVariantLight = Color(0xFFBECAC3);

  /// Inverse surface — Snackbar bg
  static const Color inverseSurfaceLight = Color(0xFF2B322E);

  /// Inverse primary — Snackbar accent
  static const Color inversePrimaryLight = Color(0xFF5FDAB1);

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME — Green-tinted dark neutrals
  // ══════════════════════════════════════════════════════════════════════════

  /// Arka plan — Yeşil tonlu koyu (saf siyah DEĞİL)
  static const Color backgroundDark = Color(0xFF0C1511);

  /// Yüzey — Koyu yeşil-gri (card, modal, panel)
  static const Color surfaceDark = Color(0xFF1B221E);

  /// Yüzey varyant — Biraz daha açık
  static const Color surfaceVariantDark = Color(0xFF303733);

  /// Surface container lowest
  static const Color surfaceContainerLowestDark = Color(0xFF060F0B);

  /// Surface container low
  static const Color surfaceContainerLowDark = Color(0xFF161D19);

  /// Surface container
  static const Color surfaceContainerDark = Color(0xFF1B221E);

  /// Surface container high
  static const Color surfaceContainerHighDark = Color(0xFF262D29);

  /// Surface container highest
  static const Color surfaceContainerHighestDark = Color(0xFF303733);

  /// Ana metin — Açık gri (koyu yüzeylerde)
  static const Color textPrimaryDark = Color(0xFFDDE5DF);

  /// İkincil metin — Mist
  static const Color textSecondaryDark = Color(0xFFBECAC3);

  /// Üçüncül metin
  static const Color textTertiaryDark = Color(0xFF88948D);

  /// Disabled metin
  static const Color textDisabledDark = Color(0xFF3E4943);

  /// Border
  static const Color outlineDark = Color(0xFF88948D);

  /// Border varyant
  static const Color outlineVariantDark = Color(0xFF3E4943);

  /// Inverse surface — Snackbar bg
  static const Color inverseSurfaceDark = Color(0xFFDDE5DF);

  /// Inverse primary — Snackbar accent
  static const Color inversePrimaryDark = Color(0xFF006B53);

  // ══════════════════════════════════════════════════════════════════════════
  // PAPER COLORS
  // ══════════════════════════════════════════════════════════════════════════

  /// Krem/sarı kağıt rengi
  static const Color paperCream = Color(0xFFFFFDE7);

  // ══════════════════════════════════════════════════════════════════════════
  // FOLDER COLORS (12)
  // ══════════════════════════════════════════════════════════════════════════

  /// Klasör renk seçenekleri — ilk renk artık emerald
  static const List<Color> folderColors = [
    Color(0xFF00B988), // Emerald (brand)
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
    Color(0xFF006B53), // Emerald (was Blue)
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
    Color(0x80006B53), // Emerald (was Blue)
    Color(0x80EC4899), // Pink
    Color(0x808B5CF6), // Purple
    Color(0x80F97316), // Orange
  ];
}
