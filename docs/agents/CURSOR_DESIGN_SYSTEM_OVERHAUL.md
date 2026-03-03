# 🎨 CURSOR TALİMATI: Design System Overhaul — Font + Renk + Shadow

> **Tarih:** 3 Mart 2026
> **Hazırlayan:** Senior Architect (Claude Opus)
> **Uygulayacak:** Cursor IDE Agent
> **Branch:** `feature/design-system-overhaul`
> **Öncelik:** Yüksek — Tüm adımlar sırasıyla uygulanacak

---

## 🎯 AMAÇ

Uygulamanın tüm renk paletini `#00B988` (Emerald Green) + beyaz bazlı M3 paletine dönüştür, fontları Plus Jakarta Sans + Inter olarak güncelle ve soft green-tinted shadow sistemi ekle. Mevcut token-based yapı korunacak, sadece değerler değişecek.

---

## ÖN KOŞULLAR

```bash
git checkout -b feature/design-system-overhaul
flutter pub add google_fonts
```

`pubspec.yaml`'da `google_fonts: ^8.0.1` olduğunu doğrula.

---

## ADIM 1: Renk Token'larını Güncelle

**Dosya:** `example_app/lib/core/theme/tokens/app_colors.dart`

Mevcut `AppColors` sınıfının tamamını aşağıdakiyle **DEĞİŞTİR**. Mevcut yapıyı (abstract class, bölüm yorumları, folder/pen/highlighter renkleri) koru. Sadece brand, semantic, light theme ve dark theme renklerini güncelle:

```dart
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

  /// Arka plan — Yeşil tonlu çok açık
  static const Color backgroundLight = Color(0xFFF4FDF7);

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
  // PEN QUICK COLORS (8) — DEĞİŞMEDİ
  // ══════════════════════════════════════════════════════════════════════════

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
  // HIGHLIGHTER COLORS (6) — DEĞİŞMEDİ
  // ══════════════════════════════════════════════════════════════════════════

  static const List<Color> highlighterColors = [
    Color(0x80FACC15), // Yellow
    Color(0x804ADE80), // Green
    Color(0x80006B53), // Emerald (was Blue)
    Color(0x80EC4899), // Pink
    Color(0x808B5CF6), // Purple
    Color(0x80F97316), // Orange
  ];
}
```

### Dikkat Edilecekler:
- Mevcut `folderColors` listesi 12 eleman, yeni de 12 eleman olmalı
- `penQuickColors` ve `highlighterColors` mavi yerine emerald'a güncellendi
- Dark mode renkleri ayrı static const olarak tanımlandı
- Tüm yorum ve section başlıkları korundu

---

## ADIM 2: ColorScheme Güncelle

**Dosya:** `example_app/lib/core/theme/app_theme.dart`

`_lightColorScheme` ve `_darkColorScheme` getter'larını güncelle:

```dart
static ColorScheme get _lightColorScheme => const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.accent,
      onTertiary: AppColors.onAccent,
      tertiaryContainer: AppColors.accentContainer,
      onTertiaryContainer: AppColors.onAccentContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      surfaceContainerLowest: AppColors.surfaceContainerLowestLight,
      surfaceContainerLow: AppColors.surfaceContainerLowLight,
      surfaceContainer: AppColors.surfaceContainerLight,
      surfaceContainerHigh: AppColors.surfaceContainerHighLight,
      surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineVariantLight,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.inverseSurfaceLight,
      inversePrimary: AppColors.inversePrimaryLight,
      surfaceTint: AppColors.primary,
    );

  static ColorScheme get _darkColorScheme => const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDarkMode,
      onPrimary: AppColors.onPrimaryDarkMode,
      primaryContainer: AppColors.primaryContainerDarkMode,
      onPrimaryContainer: AppColors.onPrimaryContainerDarkMode,
      secondary: AppColors.secondaryDarkMode,
      onSecondary: AppColors.onSecondaryDarkMode,
      secondaryContainer: AppColors.secondaryContainerDarkMode,
      onSecondaryContainer: AppColors.onSecondaryContainerDarkMode,
      tertiary: Color(0xFFBAC8E3),
      onTertiary: Color(0xFF253148),
      tertiaryContainer: Color(0xFF3B4760),
      onTertiaryContainer: Color(0xFFD7E3FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
      surfaceContainerLow: AppColors.surfaceContainerLowDark,
      surfaceContainer: AppColors.surfaceContainerDark,
      surfaceContainerHigh: AppColors.surfaceContainerHighDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.inverseSurfaceDark,
      inversePrimary: AppColors.inversePrimaryDark,
      surfaceTint: AppColors.primaryDarkMode,
    );
```

> **NOT:** `ColorScheme.light()` ve `ColorScheme.dark()` constructor'ları yerine `ColorScheme()` constructor'ını kullan çünkü tüm rolleri açıkça belirtiyoruz.

---

## ADIM 3: Font Sistemi — Plus Jakarta Sans + Inter

**Yeni dosya oluştur:** `example_app/lib/core/theme/tokens/app_typography.dart`

Eğer bu dosya zaten varsa içeriğini aşağıdakiyle değiştir. Yoksa oluştur:

```dart
/// ElyaNotes Design System - Typography Tokens
///
/// Plus Jakarta Sans: Display, Headline, Title (branding/headings)
/// Inter: Body, Label (okuma/UI)
///
/// Onay: 3 Mart 2026
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulama tipografi sistemi.
///
/// M3 type scale'i Plus Jakarta Sans + Inter ile yapılandırır.
abstract class AppTypography {
  /// Heading font ailesi
  static String get headingFontFamily => 'Plus Jakarta Sans';

  /// Body font ailesi
  static String get bodyFontFamily => 'Inter';

  /// Brightness'a göre tam TextTheme üret
  static TextTheme create(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    // Inter'i tüm roller için base olarak uygula
    final interTheme = GoogleFonts.interTextTheme(base);

    // Display, Headline ve Title Large'ı Plus Jakarta Sans ile override et
    return interTheme.copyWith(
      // ── Display ──────────────────────────────────────────
      displayLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w400,
      ),

      // ── Headline ─────────────────────────────────────────
      headlineLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w600,
      ),

      // ── Title ────────────────────────────────────────────
      titleLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),

      // ── Body ─────────────────────────────────────────────
      bodyLarge: GoogleFonts.inter(
        textStyle: base.bodyLarge,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: base.bodyMedium,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: base.bodySmall,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),

      // ── Label ────────────────────────────────────────────
      labelLarge: GoogleFonts.inter(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: base.labelMedium,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: base.labelSmall,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

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
```

### `app_theme.dart`'taki `_textTheme` metodunu güncelle:

Mevcut `_textTheme` metodunu kaldır ve yerine:

```dart
// import ekle (dosyanın üstüne)
import 'tokens/app_typography.dart'; // YENI EKLENEN IMPORT

// _build metodu veya _textTheme yerine, light/dark ThemeData'larda:
textTheme: AppTypography.create(Brightness.light),  // light theme için
textTheme: AppTypography.create(Brightness.dark),    // dark theme için
```

Mevcut `_textTheme({required Color primary, required Color secondary})` helper metodu varsa, onu `AppTypography.create(brightness)` ile değiştir. Renk ataması artık ColorScheme üzerinden otomatik yapılacak.

---

## ADIM 4: Shadow Sistemi

**Yeni dosya oluştur:** `example_app/lib/core/theme/tokens/app_shadows.dart`

```dart
/// ElyaNotes Design System - Shadow Tokens
///
/// Green-tinted soft shadow sistemi.
/// Light modda 2 katmanlı (tint + black), dark modda minimal shadow.
///
/// Onay: 3 Mart 2026
library;

import 'package:flutter/material.dart';

/// Uygulama shadow sistemi — #00B988 tinted
abstract class AppShadows {
  static const Color _tint = Color(0xFF00B988);

  /// Level 1 — Resting card shadow
  static List<BoxShadow> cardResting(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.06),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        offset: const Offset(0, 1),
        blurRadius: 3,
      ),
    ];
  }

  /// Level 3 — Elevated/active card, dragging
  static List<BoxShadow> cardElevated(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        offset: const Offset(0, 4),
        blurRadius: 12,
      ),
    ];
  }

  /// Level 4 — Modal, dialog
  static List<BoxShadow> modal(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.08),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          offset: const Offset(0, 12),
          blurRadius: 32,
          spreadRadius: -4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.40),
        offset: const Offset(0, 8),
        blurRadius: 24,
      ),
    ];
  }

  /// Level 4 — FAB (dark modda primary glow)
  static List<BoxShadow> fab(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.15),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: _tint.withValues(alpha: 0.20),
        offset: const Offset(0, 4),
        blurRadius: 16,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        offset: const Offset(0, 6),
        blurRadius: 20,
      ),
    ];
  }

  /// Toolbar shadow — çok ince
  static List<BoxShadow> toolbar(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ];
  }
}
```

---

## ADIM 5: Barrel Export Güncelle

**Dosya:** `example_app/lib/core/theme/tokens/index.dart`

Bu dosyaya yeni export'ları ekle (mevcutları koru):

```dart
export 'app_colors.dart';
export 'app_shadows.dart';      // YENİ
export 'app_typography.dart';   // YENİ
// ... mevcut diğer export'lar
```

Eğer `app_spacing.dart`, `app_border_radius.dart` gibi başka token dosyaları varsa onları da koru.

---

## ADIM 6: AppTheme Component Tema Güncellemeleri

**Dosya:** `example_app/lib/core/theme/app_theme.dart`

Mevcut component theme'leri şu şekilde güncelle (değişen kısımlar):

### AppBar:
```dart
appBarTheme: AppBarTheme(
  centerTitle: false,
  elevation: 0,
  scrolledUnderElevation: 1,
  backgroundColor: colorScheme.surface,
  foregroundColor: colorScheme.onSurface,
  surfaceTintColor: colorScheme.surfaceTint,
  titleTextStyle: AppTypography.create(brightness).titleLarge?.copyWith(
    color: colorScheme.onSurface,
  ),
),
```

### Card:
```dart
cardTheme: CardTheme(
  elevation: 0, // Shadow'u custom AppShadows ile veriyoruz
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  color: isLight
      ? AppColors.surfaceContainerLowLight
      : AppColors.surfaceContainerLowDark,
  clipBehavior: Clip.antiAliasWithSaveLayer,
),
```

### FAB:
```dart
floatingActionButtonTheme: FloatingActionButtonThemeData(
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  backgroundColor: colorScheme.primaryContainer,
  foregroundColor: colorScheme.onPrimaryContainer,
),
```

### Dialog:
```dart
dialogTheme: DialogTheme(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(28),
  ),
  backgroundColor: isLight
      ? AppColors.surfaceContainerHighLight
      : AppColors.surfaceContainerHighDark,
),
```

### BottomSheet:
```dart
bottomSheetTheme: BottomSheetThemeData(
  backgroundColor: isLight
      ? AppColors.surfaceContainerLowLight
      : AppColors.surfaceContainerLowDark,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(28),
    ),
  ),
  showDragHandle: true,
),
```

### Input:
```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: (isLight
          ? AppColors.surfaceContainerHighestLight
          : AppColors.surfaceContainerHighestDark)
      .withValues(alpha: 0.5),
  contentPadding: const EdgeInsets.symmetric(
    horizontal: 16, vertical: 12,
  ),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colorScheme.outline),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: colorScheme.outline.withValues(alpha: 0.5),
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: colorScheme.primary, width: 2,
    ),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colorScheme.error),
  ),
),
```

---

## ADIM 7: Shadow Uygulama — Widget'larda

Uygulamadaki `BoxDecoration` kullanan tüm widget'larda shadow ekle/güncelle. Aranacak pattern'ler:

### 7a. Document Card widget'ları:
Tüm `DocumentCard`, `NoteCard` veya card benzeri widget'ları bul. `BoxDecoration` kullanıyorlarsa shadow ekle:

```dart
// ÖNCE: Shadow yok veya hardcoded shadow
Container(
  decoration: BoxDecoration(
    color: theme.cardColor,
    borderRadius: BorderRadius.circular(16),
  ),
)

// SONRA: AppShadows ile
Container(
  decoration: BoxDecoration(
    color: theme.cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppShadows.cardResting(theme.brightness),
  ),
)
```

### 7b. Toolbar/Navigation widget'ları:
```dart
boxShadow: AppShadows.toolbar(theme.brightness),
```

### 7c. Modal/Dialog widget'ları (custom olanlar):
```dart
boxShadow: AppShadows.modal(theme.brightness),
```

### 7d. FAB (custom Container ile oluşturulmuşsa):
```dart
boxShadow: AppShadows.fab(theme.brightness),
```

**ARA ve DEĞİŞTİR:**
Projede `BoxShadow(` pattern'ini ara. Tüm hardcoded shadow'ları `AppShadows` token'larıyla değiştir.

Ayrıca `boxShadow: [` pattern'ini ara — bunlar da muhtemelen güncellenmeli.

---

## ADIM 8: Uygulamada Kalan Hardcoded Renkleri Temizle

Tüm dosyalarda şu pattern'leri ara ve AppColors token'larıyla değiştir:

```
Color(0xFF38434F)  → AppColors ile değiştir (eski primary)
Color(0xFF4A8AF7)  → AppColors ile değiştir (eski accent)
Color(0xFF5B7CFF)  → AppColors ile değiştir (eski design system primary)
Color(0xFFFFB547)  → AppColors ile değiştir (eski accent amber)
Colors.white       → Theme.of(context).colorScheme.surface veya onPrimary
Colors.black       → Theme.of(context).colorScheme.onSurface
```

**Dikkat:** Canvas ve drawing katmanındaki renklere (CanvasColorScheme) dokunma! Sadece UI katmanını güncelle.

---

## ADIM 9: Logo Stili

Uygulamada logo/brand text gösteren yerleri bul (muhtemelen AppBar title, splash, sidebar header). Bunları `AppTypography.logo()` ile güncelle:

```dart
// Mevcut logo text'i
Text(
  'StarNote',
  style: AppTypography.logo(
    fontSize: 22,
    color: theme.colorScheme.primary,
  ),
)
```

---

## ADIM 10: Test ve Doğrulama

```bash
# 1. Compile kontrolü
flutter analyze

# 2. Test
flutter test

# 3. Görsel kontrol — hem phone hem tablet
flutter run -d <device>
```

### Kontrol listesi:
- [ ] Light mode: Tüm ekranlarda `#00B988` ailesinin renkleri görünüyor
- [ ] Dark mode: `#5FDAB1` primary, yeşil tonlu koyu yüzeyler
- [ ] Fontlar: Başlıklar Plus Jakarta Sans, body Inter
- [ ] Shadow: Card'larda yeşil tint'li soft shadow
- [ ] Contrast: Beyaz üzerindeki primary text okunabilir
- [ ] Canvas: Drawing renkleri etkilenmemiş
- [ ] Template: Template preview renkleri çalışıyor
- [ ] Settings: Theme toggle çalışıyor

---

## COMMIT

```bash
git add .
git commit -m "feat(theme): overhaul design system — #00B988 palette, Plus Jakarta Sans + Inter, soft shadows

- Replace Slate Charcoal palette with #00B988 Emerald Green M3 palette
- Add Plus Jakarta Sans for headings, Inter for body (AppTypography)
- Add green-tinted soft shadow system (AppShadows)
- Update ColorScheme with full M3 role mapping (40+ roles)
- Update all component themes (AppBar, Card, Dialog, Input, FAB, etc.)
- Dark mode uses green-tinted neutrals instead of pure black
- Logo text uses Plus Jakarta Sans ExtraBold
- All hardcoded colors replaced with design tokens"

git push origin feature/design-system-overhaul
```

---

## ⚠️ YAPILMAMASI GEREKENLER

1. **Canvas/Drawing katmanına DOKUNMA** — `CanvasColorScheme`, `DrawingTheme`, painter'lar olduğu gibi kalacak
2. **Package'lara (drawing_core, drawing_ui) DOKUNMA** — sadece `example_app` değişecek
3. **Test dosyalarında hardcoded renk beklentileri varsa** güncelle
4. **`pubspec.yaml`'da font asset'leri eklemeye GEREK YOK** — `google_fonts` package runtime'da indiriyor (ilk açılışta). Offline kullanım istenirse sonra `assets/google_fonts/` eklenebilir
5. **`withOpacity()` KULLANMA** — Flutter 3.27+ deprecation. `withValues(alpha: 0.xx)` kullan

---

## DOSYA DEĞİŞİKLİK ÖZETİ

| Dosya | İşlem |
|-------|-------|
| `tokens/app_colors.dart` | ✏️ Tamamen güncelle |
| `tokens/app_typography.dart` | 🆕 Yeni oluştur |
| `tokens/app_shadows.dart` | 🆕 Yeni oluştur |
| `tokens/index.dart` | ✏️ Export ekle |
| `app_theme.dart` | ✏️ ColorScheme + TextTheme + Components güncelle |
| `pubspec.yaml` | ✏️ google_fonts dependency kontrol |
| Widget dosyaları (card, sidebar, vb.) | ✏️ Hardcoded renk/shadow temizle |
