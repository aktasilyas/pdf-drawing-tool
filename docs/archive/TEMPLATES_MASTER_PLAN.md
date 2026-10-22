# 📋 TEMPLATES MASTER PLAN

> **Oluşturulma:** 2025-01-27
> **Amaç:** Kapsamlı, genişletilebilir template sistemi
> **Kural:** Her adım ayrı commit, mevcut kod bozulmayacak

---

## 🎯 HEDEFLER

1. **44+ Template Seçeneği** - 6 kategoride
2. **Renk Özelleştirmesi** - Paper color + line color
3. **Standart Boyutlar** - A4, A5, Letter, Legal, Custom
4. **Premium/Free Ayrımı** - Monetization ready
5. **Responsive UI** - Tablet + Phone optimized
6. **Future-proof** - Kolay genişletilebilir

---

## 📦 MİMARİ YAPI

### Paket Dağılımı

drawing_core (PURE DART):
- models/template_category.dart (YENİ)
- models/template_pattern.dart (YENİ)
- models/template.dart (YENİ)
- models/paper_size.dart (YENİ)
- services/template_registry.dart (YENİ)

drawing_ui (FLUTTER):
- widgets/template_picker/template_picker.dart
- widgets/template_picker/template_card.dart
- widgets/template_picker/template_grid.dart
- widgets/template_picker/category_tabs.dart
- widgets/template_picker/template_preview.dart
- widgets/paper_size_picker.dart
- widgets/color_customizer.dart

example_app:
- Mevcut new_document_dialog.dart güncelleme

---

## 📐 MODEL TASARIMI

### TemplateCategory Enum

```dart
enum TemplateCategory {
  basic,        // Boş, çizgili, kareli - FREE
  productivity, // Cornell, To-Do, Meeting - PREMIUM
  creative,     // Storyboard, Music, Art - PREMIUM
  education,    // Math, Handwriting - PREMIUM
  planning,     // Calendar, Weekly - PREMIUM
  special,      // Isometric, Hex - PREMIUM
}
```

### TemplatePattern Enum

```dart
enum TemplatePattern {
  blank,
  thinLines,
  mediumLines,
  thickLines,
  smallGrid,
  mediumGrid,
  largeGrid,
  smallDots,
  mediumDots,
  largeDots,
  isometric,
  hexagonal,
  cornell,
  music,
  handwriting,
  calligraphy,
}
```

### Template Model

```dart
class Template {
  final String id;
  final String name;
  final String nameEn;
  final TemplateCategory category;
  final TemplatePattern pattern;
  final bool isPremium;
  final double spacing;
  final double lineWidth;
  final int defaultLineColor;
  final int defaultBackgroundColor;
  final Map<String, dynamic>? extraData;
  
  const Template({...});
  
  factory Template.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### PaperSize Model

```dart
enum PaperSizePreset { a4, a5, a6, letter, legal, square, widescreen, custom }

class PaperSize {
  final double widthMm;
  final double heightMm;
  final PaperSizePreset preset;
  final bool isLandscape;
  
  double get widthPx => widthMm * 72 / 25.4;
  double get heightPx => heightMm * 72 / 25.4;
  
  static const a4 = PaperSize(widthMm: 210, heightMm: 297, preset: PaperSizePreset.a4);
  static const a5 = PaperSize(widthMm: 148, heightMm: 210, preset: PaperSizePreset.a5);
  static const letter = PaperSize(widthMm: 215.9, heightMm: 279.4, preset: PaperSizePreset.letter);
}
```

---

## 🎨 TEMPLATE LİSTESİ (44 Adet)

### Basic (Free) - 12 Template

| ID | İsim | Pattern | Spacing |
|----|------|---------|---------|
| blank_white | Boş (Beyaz) | blank | - |
| blank_cream | Boş (Krem) | blank | - |
| blank_gray | Boş (Gri) | blank | - |
| thin_lined | İnce Çizgili | thinLines | 6mm |
| medium_lined | Orta Çizgili | mediumLines | 8mm |
| thick_lined | Kalın Çizgili | thickLines | 10mm |
| small_grid | Küçük Kareli | smallGrid | 5mm |
| medium_grid | Orta Kareli | mediumGrid | 7mm |
| large_grid | Büyük Kareli | largeGrid | 10mm |
| small_dots | Küçük Noktalı | smallDots | 5mm |
| medium_dots | Orta Noktalı | mediumDots | 7mm |
| large_dots | Büyük Noktalı | largeDots | 10mm |

### Productivity (Premium) - 8 Template

| ID | İsim | Özellik |
|----|------|---------|
| cornell | Cornell Notes | Sol margin + alt özet |
| todo_list | Yapılacaklar | Checkbox alanları |
| meeting_notes | Toplantı Notu | Başlık + katılımcı + aksiyon |
| daily_planner | Günlük Plan | Saat dilimleri |
| weekly_planner | Haftalık Plan | 7 gün grid |
| project_tracker | Proje Takip | Milestone timeline |
| habit_tracker | Alışkanlık Takip | 30 gün grid |
| goal_setting | Hedef Belirleme | SMART format |

### Creative (Premium) - 6 Template

| ID | İsim | Özellik |
|----|------|---------|
| storyboard | Storyboard | 6 kare film şeridi |
| music_staff | Nota Kağıdı | 5 çizgi müzik notası |
| comic_panel | Çizgi Roman | Panel layout |
| sketch_guide | Eskiz Rehber | Perspektif çizgileri |
| calligraphy | Kaligrafi | Açılı çizgiler |
| lettering | Lettering | Baseline + x-height |

### Education (Premium) - 6 Template

| ID | İsim | Özellik |
|----|------|---------|
| math_grid | Matematik | Kareli + koordinat |
| graph_paper | Grafik Kağıdı | Büyük grid + eksenler |
| handwriting | El Yazısı | Çizgili + orta çizgi |
| chinese_grid | Çince/Japonca | Kare karakterler için |
| vocabulary | Kelime Defteri | 2 sütun |
| flashcard | Flash Kart | Ön/arka bölüm |

### Planning (Premium) - 6 Template

| ID | İsim | Özellik |
|----|------|---------|
| monthly_cal | Aylık Takvim | 5x7 grid |
| yearly_overview | Yıllık Bakış | 12 ay mini |
| budget_tracker | Bütçe Takip | Gelir/gider sütunları |
| meal_planner | Yemek Planı | Haftalık öğünler |
| fitness_log | Fitness Log | Set/tekrar kayıt |
| travel_itinerary | Seyahat Planı | Gün bazlı timeline |

### Special (Premium) - 6 Template

| ID | İsim | Özellik |
|----|------|---------|
| isometric | İzometrik | 30° açılı grid |
| hexagonal | Altıgen | Hex grid |
| seyes | Séyès (Fransız) | Kareli + çizgili |
| engineer_pad | Mühendis | 5mm grid + margin |
| legal_pad | Legal Pad | Sarı + margin |
| manuscript | El Yazması | Vintage çizgili |

---

## 📱 RESPONSIVE UI

### Breakpoints
- Phone: < 600px → 3 column grid, bottom sheet picker
- Tablet: >= 600px → 5 column grid, side panel picker

### Phone Layout
```
┌─────────────────────────────┐
│ ← Şablon Seç                │
├─────────────────────────────┤
│ [Basic] [Prod] [Crea] [>]   │ ← Horizontal scroll
├─────────────────────────────┤
│ ┌───┐ ┌───┐ ┌───┐          │
│ │   │ │≡≡≡│ │###│          │ ← 3 column
│ └───┘ └───┘ └───┘          │
├─────────────────────────────┤
│ [Boyut: A4 ▼] [Renk: ⚪ ▼]  │
├─────────────────────────────┤
│       [ Oluştur ]           │
└─────────────────────────────┘
```

### Tablet Layout
```
┌──────────────────────────────────────────────────────────┐
│ ← Şablon Seç                              [Boyut: A4 ▼]  │
├────────────┬─────────────────────────────────────────────┤
│ ○ Basic    │  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐            │
│ ○ Product. │  │   │ │≡≡≡│ │###│ │•••│ │🔒│             │ ← 5 column
│ ○ Creative │  └───┘ └───┘ └───┘ └───┘ └───┘            │
│ ○ Educat.  │                                            │
│ ○ Planning │           [ Önizleme ]                     │
│ ○ Special  │                                            │
├────────────┴─────────────────────────────────────────────┤
│ Kağıt: ⚪⚪⚪  Çizgi: ⚫⚫⚫           [ Oluştur ]        │
└──────────────────────────────────────────────────────────┘
```

---

## 🔢 GELİŞTİRME ADIMLARI

### Phase T1: Core Models (drawing_core)
Branch: feature/templates-core

1. TemplateCategory enum oluştur
2. TemplatePattern enum oluştur
3. Template model oluştur (JSON serialization dahil)
4. PaperSizePreset enum oluştur
5. PaperSize model oluştur
6. TemplateRegistry oluştur (44 template tanımı)
7. Unit testler yaz
8. Barrel exports güncelle

### Phase T2: Pattern Painters (drawing_ui)
Branch: feature/templates-painters

1. TemplatePatternPainter base class
2. Basic patterns (lined, grid, dots)
3. Special patterns (isometric, hex, cornell)
4. Complex patterns (music, handwriting)
5. Widget testler

### Phase T3: Template Picker UI (drawing_ui)
Branch: feature/templates-picker

1. TemplateCard widget (responsive)
2. CategoryTabs widget
3. TemplateGrid widget (responsive)
4. TemplatePreview widget
5. PaperSizePicker widget
6. ColorCustomizer widget
7. TemplatePicker ana widget
8. Responsive layout (phone/tablet)
9. Widget testler

### Phase T4: App Integration (example_app)
Branch: feature/templates-integration

1. NewDocumentDialog güncelle
2. Premium check entegrasyonu
3. DocumentCard güncelle
4. CreateDocumentUseCase güncelle
5. Integration testler

---

## ⚠️ CURSOR KURALLARI

1. BRANCH OLUŞTURMADAN KOD YAZMA
2. HER ADIM SONRASI TEST YAZ
3. MEVCUT PageBackground BOZMA
4. RESPONSIVE ZORUNLU (LayoutBuilder kullan)
5. İLYAS ONAYI OLMADAN COMMIT YAPMA

### Backward Compatibility

```dart
// ✅ DOĞRU: Yeni pattern ekle
enum BackgroundType {
  blank,
  grid,      // Mevcut - DOKUNMA
  lined,     // Mevcut - DOKUNMA
  dotted,    // Mevcut - DOKUNMA
  pdf,       // Mevcut - DOKUNMA
  template,  // YENİ - TemplatePattern kullanır
}
```

---

## 📊 TAHMİNİ SÜRE

| Phase | Süre |
|-------|------|
| T1: Core Models | 3-4 saat |
| T2: Pattern Painters | 4-5 saat |
| T3: Template Picker UI | 5-6 saat |
| T4: App Integration | 2-3 saat |
| TOPLAM | 14-18 saat |

---

*Templates Master Plan - v1.0*
