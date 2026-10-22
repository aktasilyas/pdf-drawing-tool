# Elyanotes Design System & UI Refactoring Master Plan

> **Versiyon:** 1.0  
> **Tarih:** 1 Şubat 2026  
> **Hedef:** Production-ready, GoodNotes/Flexcil kalitesinde not uygulaması  
> **Platformlar:** Android/iOS - Mobil & Tablet  
> **Roller:** İlyas (Product Owner) → Claude (Architect) → Cursor (Senior Flutter Developer)

---

## 📋 İçindekiler

1. [Executive Summary](#1-executive-summary)
2. [Renk Paleti (ONAYLANDI)](#2-renk-paleti)
3. [Design Tokens](#3-design-tokens)
4. [Component Library](#4-component-library)
5. [Responsive System](#5-responsive-system)
6. [Screen Specifications](#6-screen-specifications)
7. [Phase Timeline](#7-phase-timeline)
8. [Quality Standards](#8-quality-standards)
9. [File Structure](#9-file-structure)

---

## 1. Executive Summary

### 🎯 Vizyon
GoodNotes, Flexcil ve Notability ile rekabet edebilecek, kullanıcı deneyimi odaklı, performanslı bir not alma uygulaması.

### 🔑 Temel Prensipler

| Prensip | Açıklama |
|---------|----------|
| **Canvas-First** | Araçlar tuvale destek olmalı, domine etmemeli |
| **Minimalist UI** | Dikkat dağıtıcı unsurları minimize et |
| **Responsive** | Mobil ve tablet için optimize edilmiş ayrı deneyimler |
| **Performans** | 60 FPS rendering, <5ms hit test |
| **SOLID** | Her dosya <300 satır, tek sorumluluk |
| **Premium Hissi** | Modern, soft, profesyonel görünüm |

---

## 2. Renk Paleti

### ✅ ONAYLANDI (1 Şubat 2026)

```
┌─────────────────────────────────────────────────────────────────┐
│                    ELYANOTES COLOR PALETTE                      │
├─────────────────────────────────────────────────────────────────┤
│  PRIMARY         │  #5B7CFF  │  Light Indigo / Creative Blue   │
│  PRIMARY LIGHT   │  #7B96FF  │  Hover states                   │
│  PRIMARY DARK    │  #4A68E0  │  Pressed states                 │
├─────────────────────────────────────────────────────────────────┤
│  ACCENT          │  #FFB547  │  Amber Gold (sınırlı kullan!)   │
├─────────────────────────────────────────────────────────────────┤
│  SUCCESS         │  #4ADE80  │  Green                          │
│  WARNING         │  #FACC15  │  Yellow                         │
│  ERROR           │  #EF4444  │  Red                            │
├─────────────────────────────────────────────────────────────────┤
│                      LIGHT THEME                                │
│  Background      │  #F5F7FB  │  Soft blue-gray (göz yormaz)    │
│  Surface         │  #FFFFFF  │  Cards, modals                  │
│  Text Primary    │  #1B1F2A  │  Ana metin                      │
│  Text Secondary  │  #6B7280  │  İkincil metin                  │
│  Outline         │  #E5E7EB  │  Borders, dividers              │
├─────────────────────────────────────────────────────────────────┤
│                      DARK THEME                                 │
│  Background      │  #121212  │  OLED friendly                  │
│  Surface         │  #1E1E1E  │  Cards, modals                  │
│  Text Primary    │  #F4F4F4  │  Ana metin                      │
│  Text Secondary  │  #A0A0A0  │  İkincil metin                  │
│  Outline         │  #2C2C2C  │  Borders, dividers              │
└─────────────────────────────────────────────────────────────────┘
```

### Accent Kullanım Kuralları (ÖNEMLİ!)

Amber (#FFB547) çok dikkat çekici, sadece şu durumlarda kullan:
- ✅ Slider thumb
- ✅ Toggle switch (aktif)
- ✅ Star/Favorite icon
- ✅ Önemli badge'ler
- ❌ Büyük butonlar (primary kullan)
- ❌ Çok fazla alanda

---

## 3. Design Tokens

### 3.1 Colors (`lib/core/theme/tokens/app_colors.dart`)

```dart
import 'package:flutter/material.dart';

/// Elyanotes Design System - Color Tokens
/// Onay: 1 Şubat 2026
abstract class AppColors {
  // BRAND
  static const Color primary = Color(0xFF5B7CFF);
  static const Color primaryLight = Color(0xFF7B96FF);
  static const Color primaryDark = Color(0xFF4A68E0);
  static const Color onPrimary = Colors.white;
  
  static const Color accent = Color(0xFFFFB547);
  static const Color onAccent = Color(0xFF1B1F2A);

  // SEMANTIC
  static const Color success = Color(0xFF4ADE80);
  static const Color onSuccess = Colors.white;
  static const Color warning = Color(0xFFFACC15);
  static const Color onWarning = Color(0xFF1B1F2A);
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Colors.white;
  static const Color info = Color(0xFF5B7CFF);
  static const Color onInfo = Colors.white;

  // LIGHT THEME
  static const Color backgroundLight = Color(0xFFF5F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F2F5);
  static const Color textPrimaryLight = Color(0xFF1B1F2A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textDisabledLight = Color(0xFFD1D5DB);
  static const Color outlineLight = Color(0xFFE5E7EB);
  static const Color outlineVariantLight = Color(0xFFD1D5DB);

  // DARK THEME
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  static const Color textPrimaryDark = Color(0xFFF4F4F4);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color textDisabledDark = Color(0xFF4B5563);
  static const Color outlineDark = Color(0xFF2C2C2C);
  static const Color outlineVariantDark = Color(0xFF404040);

  // FOLDER COLORS (12)
  static const List<Color> folderColors = [
    Color(0xFF5B7CFF), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFFFB547),
    Color(0xFF4ADE80), Color(0xFF14B8A6), Color(0xFF06B6D4),
    Color(0xFF3B82F6), Color(0xFF6B7280), Color(0xFF78716C),
  ];

  // PEN QUICK COLORS (8)
  static const List<Color> penQuickColors = [
    Color(0xFF1B1F2A), Color(0xFF6B7280), Color(0xFFEF4444),
    Color(0xFFF97316), Color(0xFFFACC15), Color(0xFF4ADE80),
    Color(0xFF5B7CFF), Color(0xFF8B5CF6),
  ];

  // HIGHLIGHTER COLORS (6 - yarı saydam)
  static const List<Color> highlighterColors = [
    Color(0x80FACC15), Color(0x804ADE80), Color(0x805B7CFF),
    Color(0x80EC4899), Color(0x808B5CF6), Color(0x80F97316),
  ];
}
```

### 3.2 Spacing (`app_spacing.dart`) - 4dp Grid

```dart
abstract class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  // Semantic
  static const double screenPaddingMobile = 16;
  static const double screenPaddingTablet = 24;
  static const double cardPadding = 16;
  static const double listItemSpacing = 12;
  static const double sectionSpacing = 24;
  static const double buttonSpacing = 8;
  
  // Component Sizes
  static const double toolbarHeight = 56;
  static const double bottomNavHeight = 80;
  static const double fabSize = 56;
  static const double sidebarWidth = 280;
  static const double navigationRailWidth = 80;
}
```

### 3.3 Border Radius (`app_radius.dart`)

```dart
abstract class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;   // ✅ STANDART (Onaylı)
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double full = 999;
  
  // Semantic
  static const double button = md;       // 10
  static const double card = lg;         // 12
  static const double modal = xl;        // 16
  static const double bottomSheet = xxl; // 20
  static const double textField = md;    // 10
}
```

### 3.4 Typography (`app_typography.dart`)

```dart
abstract class AppTypography {
  // Display - Splash, Hero
  static const TextStyle displayLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  static const TextStyle displayMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);

  // Headline - Screen titles
  static const TextStyle headlineLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const TextStyle headlineMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle headlineSmall = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  // Title - Card titles
  static const TextStyle titleLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle titleMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  // Body - Content
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);

  // Label - Buttons
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  // Caption
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
}
```

### 3.5 Icon Sizes, Shadows, Durations

```dart
// Icon Sizes
abstract class AppIconSize {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double huge = 48;
}

// Shadows
abstract class AppShadows {
  static List<BoxShadow> get sm => [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))];
  static List<BoxShadow> get md => [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))];
  static List<BoxShadow> get lg => [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))];
}

// Durations
abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration snackbar = Duration(seconds: 4);
}
```

---

## 4. Component Library

### 4.1 Buttons

| Component | Variants | Sizes |
|-----------|----------|-------|
| `AppButton` | primary, secondary, outline, text, destructive | small (36), medium (44), large (52) |
| `AppIconButton` | filled, tonal, outline, ghost | small (40), medium (44), large (52) |

**Features:** loading state, icons, full width, disabled (50% opacity)

### 4.2 Inputs

| Component | Features |
|-----------|----------|
| `AppTextField` | label, hint, error, prefix icon, suffix widget |
| `AppSearchField` | search icon, clear button, debounced onChange |
| `AppPasswordField` | show/hide toggle |

### 4.3 Feedback

| Component | Features |
|-----------|----------|
| `AppModal` | Responsive: phone→bottomSheet, tablet→dialog |
| `AppConfirmDialog` | title, message, destructive option |
| `AppActionSheet` | List of actions with icons |
| `AppToast` | success, error, warning, info |
| `AppLoadingIndicator` | circular, overlay, skeleton |
| `AppEmptyState` | icon, title, description, action |

### 4.4 Layout

| Component | Features |
|-----------|----------|
| `AppCard` | elevated, filled, outlined |
| `AppListTile` | swipe actions |
| `AppSectionHeader` | title, trailing action |
| `AppAvatar` | small (32), medium (40), large (56) |
| `AppBadge` | dot or label |
| `AppChip` | selectable, deletable |

### 4.5 Navigation

| Component | Features |
|-----------|----------|
| `AdaptiveNavigation` | BottomNav ↔ NavigationRail |
| `MasterDetailLayout` | Split view for tablet |
| `ResponsiveBuilder` | Different UI per breakpoint |

---

## 5. Responsive System

### Breakpoints

```dart
compact:  0 - 599px    // Phone
medium:   600 - 839px  // Phone landscape, small tablet
expanded: 840px+       // Tablet
```

### Navigation by Device

| Device | Navigation |
|--------|------------|
| Phone (< 600px) | BottomNavigationBar |
| Tablet (≥ 600px) | NavigationRail |

### Modal Behavior

| Device | Modal Type |
|--------|------------|
| Phone | Bottom Sheet (drag handle, rounded top 20dp) |
| Tablet | Center Dialog (max-width: 560px, rounded 16dp) |

---

## 6. Screen Specifications

### 6.1 Splash Screen
- Background: Primary (#5B7CFF)
- Logo: White container, shadow
- Title: "Elyanotes" (white, bold)
- Duration: 2 seconds

### 6.2 Auth Screens
- Tablet: 50/50 split layout
- Phone: Full form, scrollable
- Google Sign-In (branding guidelines)

### 6.3 Documents Screen
- Phone: BottomNav + Drawer
- Tablet: Persistent sidebar (280px)
- Features: Grid/List, Sort, Search, Multi-select

### 6.4 Settings Screen
- Profile header
- Theme selection
- Logout (destructive)

### 6.5 Template Selection
- Category tabs
- Template grid
- Live preview

### 6.6 Drawing Screen
- Phone: Full canvas, top toolbar
- Tablet: Floating toolbar
- 8 quick colors, 3 thickness presets
- 60 FPS target

---

## 7. Phase Timeline

| Phase | İçerik | Süre |
|-------|--------|------|
| **0** | Design Tokens + Theme | 1 gün |
| **1** | Core Components (Buttons, Inputs) | 2 gün |
| **2** | Feedback Components | 1-2 gün |
| **3** | Layout Components | 1 gün |
| **4** | Responsive System | 1 gün |
| **5** | Splash Screen | 0.5 gün |
| **6** | Auth Screens | 2 gün |
| **7** | Documents Screen | 4-5 gün |
| **8** | Settings Screen | 1 gün |
| **9** | Template Selection | 1-2 gün |
| **10** | Drawing Screen | 5-7 gün |
| **11** | Polish & QA | 2-3 gün |

**Toplam:** ~22-27 gün

---

## 8. Quality Standards

| Rule | Requirement |
|------|-------------|
| File size | **Max 300 lines** |
| Touch target | **Min 48x48dp** |
| Frame rate | 60 FPS |
| Analysis | Zero warnings |
| Tests | Her component için |

---

## 9. File Structure

```
example_app/lib/core/
├── theme/
│   ├── tokens/
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   ├── app_typography.dart
│   │   ├── app_icon_sizes.dart
│   │   ├── app_shadows.dart
│   │   ├── app_durations.dart
│   │   └── index.dart
│   ├── app_theme.dart
│   └── index.dart
│
├── widgets/
│   ├── buttons/
│   ├── inputs/
│   ├── feedback/
│   ├── layout/
│   ├── navigation/
│   └── index.dart
│
└── utils/
    ├── responsive.dart
    └── validators.dart
```

---

**Hazırlayan:** Claude (Senior Architect)  
**Onaylayan:** İlyas (Product Owner)  
**Uygulayan:** Cursor (Senior Flutter Developer)
