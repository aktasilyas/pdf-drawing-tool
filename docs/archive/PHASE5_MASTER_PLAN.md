# Phase 5: Multi-Page & PDF System - Master Plan

> **Status**: NOT STARTED  
> **Branch**: `feature/phase5-multipage-pdf` ← YENİ BRANCH AÇILACAK  
> **Depends on**: Phase 4E ✅  
> **Estimated Time**: 25-35 saat

---

## 🚨 CURSOR İÇİN KRİTİK UYARILAR

### ⛔ MUTLAKA UYULMASI GEREKEN KURALLAR

```
┌─────────────────────────────────────────────────────────────────┐
│  1. YENİ BRANCH AÇARAK İLERLE                                   │
│     git checkout -b feature/phase5-multipage-pdf                │
│     ASLA main branch üzerinde çalışma!                          │
├─────────────────────────────────────────────────────────────────┤
│  2. TEST DOSYALARI ZORUNLU                                      │
│     Her yeni model/tool için ÖNCE test yaz                      │
│     Minimum %80 coverage                                        │
│     Test olmadan kod KABUL EDİLMEZ                              │
├─────────────────────────────────────────────────────────────────┤
│  3. KENDİ BAŞINA COMMIT YAPMA                                   │
│     Her adım sonunda "Ready to commit?" sor                     │
│     İlyas'ın onayını BEKLE                                      │
│     Onay almadan ASLA commit/push yapma                         │
├─────────────────────────────────────────────────────────────────┤
│  4. MEVCUT KODU BOZMA                                           │
│     Her değişiklik öncesi: flutter test                         │
│     Regression = KABUL EDİLMEZ                                  │
│     Backward compatibility ZORUNLU                              │
└─────────────────────────────────────────────────────────────────┘
```

### 📋 Her Adım Sonrası Checklist

```bash
# 1. Analyzer kontrolü
flutter analyze
# Hata varsa DURUR, devam etme

# 2. Tüm testleri çalıştır
cd packages/drawing_core && flutter test
cd ../drawing_ui && flutter test
# Başarısız test varsa DURUR

# 3. Yeni testleri çalıştır
flutter test test/unit/models/page_test.dart
# Kendi yazdığın testler geçmeli

# 4. Regression kontrolü
# Mevcut özellikler çalışıyor mu? Manuel kontrol

# 5. İlyas'a rapor ver
echo "📁 Files: ..."
echo "🧪 Tests: X passed"
echo "📝 Commit suggestion: ..."
echo "Ready to commit? (y/n)"
# ONAY BEKLE
```

---

## 🎯 Phase 5 Amacı

Çoklu sayfa desteği ve PDF import/export özelliği eklemek.

**Sonuç:** Kullanıcı birden fazla sayfada çalışabilecek, PDF dosyalarını import edebilecek ve üzerine annotation yapabilecek.

---

## 📊 Phase 5 Kapsamı

```
Phase 5: Multi-Page & PDF
├── 5A: Page Model & Document Update (~4-5 saat)
│   ├── Page model (id, size, background, content)
│   ├── DrawingDocument multi-page güncelleme
│   ├── PageSettings (size, orientation, background)
│   └── Serialization (JSON)
│
├── 5B: PageManager & Navigation (~5-6 saat)
│   ├── PageManager (CRUD operations)
│   ├── PageNavigator widget
│   ├── Page thumbnails
│   ├── Current page state
│   └── Page reordering
│
├── 5C: Memory Management (~4-5 saat)
│   ├── LRU Cache for pages
│   ├── Lazy loading strategy
│   ├── Memory budget (50MB default)
│   ├── Page unload/reload
│   └── Thumbnail cache
│
├── 5D: PDF Import (~6-8 saat)
│   ├── PDF library integration (pdf_render veya pdfx)
│   ├── PDF page extraction
│   ├── Zoom-aware DPI rendering
│   ├── PDF background layer
│   └── Import progress UI
│
├── 5E: PDF Export (~4-5 saat)
│   ├── Canvas to PDF conversion
│   ├── Vector export (strokes, shapes, text)
│   ├── Raster fallback (complex content)
│   ├── Export options UI
│   └── Progress indicator
│
└── 5F: Integration & Polish (~3-4 saat)
    ├── Full workflow test
    ├── Performance optimization
    ├── Edge case handling
    └── Documentation
```

**Tahmini Toplam Süre:** 26-33 saat

---

## 🏗️ Mimari Genel Bakış

### Güncellenmiş Model Yapısı

```
DrawingDocument (UPDATED)
├── id: String
├── title: String
├── pages: List<Page>           ← YENİ (eskiden layers)
├── currentPageIndex: int       ← YENİ
├── createdAt: DateTime
├── updatedAt: DateTime
└── settings: DocumentSettings  ← YENİ

Page (YENİ)
├── id: String
├── index: int
├── size: PageSize
├── background: PageBackground
├── layers: List<Layer>         ← Mevcut Layer yapısı
├── pdfPageIndex: int?          ← PDF import için
└── thumbnail: Uint8List?       ← Cache için

PageSize
├── width: double
├── height: double
├── preset: PagePreset? (A4, Letter, Custom)

PageBackground
├── type: BackgroundType (blank, grid, lined, dotted, pdf)
├── color: int
├── pdfData: Uint8List?         ← PDF background için
└── gridSpacing: double?
```

### Paket Dağılımı

```
drawing_core/
├── models/
│   ├── page.dart               ← YENİ
│   ├── page_size.dart          ← YENİ
│   ├── page_background.dart    ← YENİ
│   ├── document_settings.dart  ← YENİ
│   └── drawing_document.dart   ← GÜNCELLEME
├── managers/
│   ├── page_manager.dart       ← YENİ
│   └── lru_cache.dart          ← YENİ
└── serialization/
    ├── page_serializer.dart    ← YENİ
    └── document_serializer.dart ← GÜNCELLEME

drawing_ui/
├── widgets/
│   ├── page_navigator.dart     ← YENİ
│   ├── page_thumbnail.dart     ← YENİ
│   ├── page_settings_panel.dart ← YENİ
│   └── pdf_import_dialog.dart  ← YENİ
├── painters/
│   ├── page_background_painter.dart ← YENİ
│   └── pdf_background_painter.dart  ← YENİ
└── providers/
    ├── page_provider.dart      ← YENİ
    ├── pdf_provider.dart       ← YENİ
    └── document_provider.dart  ← GÜNCELLEME
```

---

## 📦 Bağımlılıklar

### Önerilen PDF Kütüphaneleri

```yaml
# drawing_ui/pubspec.yaml (veya example_app)
dependencies:
  # PDF Rendering (seçenekler)
  pdfx: ^2.6.0              # Önerilen - cross-platform
  # VEYA
  pdf_render: ^1.4.12       # Alternatif
  
  # PDF Export
  pdf: ^3.10.8              # PDF oluşturma
  
  # Thumbnail generation
  flutter_cache_manager: ^3.3.1
```

### Karar: PDF Kütüphanesi Seçimi

| Kütüphane | Avantaj | Dezavantaj |
|-----------|---------|------------|
| pdfx | Cross-platform, aktif | Biraz büyük |
| pdf_render | Hafif | Sadece mobile |
| syncfusion_flutter_pdf | Zengin özellik | Lisans gerekli |

**Öneri:** `pdfx` - cross-platform desteği için

---

## 🔢 Geliştirme Sırası (Detaylı Adımlar)

### Phase 5A: Page Model (6 Adım)

```
5A-1: PageSize ve PagePreset enum
5A-2: PageBackground model
5A-3: Page model
5A-4: DocumentSettings model
5A-5: DrawingDocument güncelleme (backward compatible!)
5A-6: Serialization ve testler
```

### Phase 5B: PageManager (6 Adım)

```
5B-1: PageManager core logic
5B-2: PageProvider (Riverpod)
5B-3: PageNavigator widget (bottom bar)
5B-4: PageThumbnail widget
5B-5: Page CRUD operations
5B-6: Page reordering ve testler
```

### Phase 5C: Memory Management (5 Adım)

```
5C-1: LRUCache generic implementation
5C-2: PageCache with memory budget
5C-3: Lazy loading strategy
5C-4: Thumbnail cache
5C-5: Memory profiling ve testler
```

### Phase 5D: PDF Import (6 Adım)

```
5D-1: PDF library integration
5D-2: PDFLoader service
5D-3: Zoom-aware DPI rendering
5D-4: PDFBackgroundPainter
5D-5: PDFImportDialog widget
5D-6: Import flow ve testler
```

### Phase 5E: PDF Export (5 Adım)

```
5E-1: PDFExporter service
5E-2: Vector content export
5E-3: Raster fallback
5E-4: ExportOptionsDialog
5E-5: Export flow ve testler
```

### Phase 5F: Integration (4 Adım)

```
5F-1: Full workflow integration
5F-2: Performance optimization
5F-3: Edge case handling
5F-4: Documentation ve final test
```

---

## ⚡ Performans Gereksinimleri

### Page Loading

```
Hedef: <100ms page switch
Strateji:
├── Preload adjacent pages (n-1, n+1)
├── Lazy load distant pages
├── LRU cache (max 5 pages in memory)
└── Thumbnail always available
```

### PDF Rendering

```
Hedef: <200ms initial render, 60 FPS pan/zoom
Strateji:
├── Zoom-aware DPI (72 × zoom × devicePixelRatio)
├── Tile-based rendering for large pages
├── Background thread rendering
└── Progressive quality (low → high)
```

### Memory Budget

```
Default: 50MB for page cache
├── ~10MB per complex page
├── Max 5 pages in memory
├── Thumbnail: 100KB max each
└── PDF background: separate cache
```

---

## 🧪 Test Stratejisi

### Unit Tests (drawing_core)

```dart
// test/unit/models/page_test.dart
void main() {
  group('Page', () {
    test('should create with default values', () {...});
    test('should serialize to JSON', () {...});
    test('should deserialize from JSON', () {...});
    test('should calculate bounds correctly', () {...});
  });
  
  group('PageManager', () {
    test('should add page', () {...});
    test('should remove page', () {...});
    test('should reorder pages', () {...});
    test('should navigate to page', () {...});
  });
  
  group('LRUCache', () {
    test('should evict least recently used', () {...});
    test('should respect memory budget', () {...});
    test('should handle concurrent access', () {...});
  });
}
```

### Widget Tests (drawing_ui)

```dart
// test/widget/page_navigator_test.dart
void main() {
  testWidgets('should display page thumbnails', (tester) async {...});
  testWidgets('should navigate on tap', (tester) async {...});
  testWidgets('should show add page button', (tester) async {...});
  testWidgets('should support reordering', (tester) async {...});
}
```

### Integration Tests

```dart
// test/integration/pdf_import_test.dart
void main() {
  testWidgets('should import PDF and create pages', (tester) async {...});
  testWidgets('should render PDF background correctly', (tester) async {...});
  testWidgets('should allow annotation on PDF', (tester) async {...});
}
```

---

## 📋 CURRENT_STATUS.md Güncelleme Şablonu

```markdown
## Quick Status

| Key | Value |
|-----|-------|
| **Current Phase** | 5 - Multi-Page & PDF |
| **Current Module** | 5A Page Model |
| **Current Step** | X/6 |
| **Last Commit** | [commit message] |
| **Branch** | feature/phase5-multipage-pdf |

---

## Phase 5 Progress

```
5A: Page Model     [______] 0/6
5B: PageManager    [______] 0/6
5C: Memory Mgmt    [______] 0/5
5D: PDF Import     [______] 0/6
5E: PDF Export     [______] 0/5
5F: Integration    [______] 0/4
```
```

---

## 🚨 Kritik Hatırlatmalar

1. **Branch:** `feature/phase5-multipage-pdf` üzerinde çalış
2. **Backward Compatibility:** Mevcut tek sayfalı dokümanlar çalışmaya devam etmeli
3. **Test First:** Her model için önce test yaz
4. **Memory:** 50MB budget'ı aşma
5. **PDF DPI:** Zoom seviyesine göre dinamik render
6. **Commit:** İlyas onayı OLMADAN commit yapma

---

## 🎯 Phase 5 Sonunda Beklenen

- ✅ Multi-page document support
- ✅ Page navigation (thumbnails)
- ✅ PDF import with annotation
- ✅ PDF export
- ✅ Memory-efficient page management
- ✅ Backward compatible with single-page docs
- ✅ %80+ test coverage
- ✅ 60 FPS performance maintained

---

*Phase 5 başarıyla tamamlanacak! 📄📑*
