# Phase 4 Başlangıç - Cursor'a Verilecek Komutlar

---

## 🚀 Phase 4'e Başlamadan Önce

### 1. Branch Oluştur

```
Yeni branch oluştur:

git checkout main
git pull origin main
git checkout -b feature/phase4-advanced-features
git push -u origin feature/phase4-advanced-features
```

---

### 2. Dökümanları Oku

```
Phase 4 dökümanları hazır. SIRAYLA oku:

1. docs/PHASE4_MASTER_PLAN.md - Genel plan ve modüller
2. docs/PHASE4_CURSOR_INSTRUCTIONS.md - Adım adım görevler
3. docs/PHASE4_ERASER_SPEC.md - Eraser detaylı spec
4. docs/PHASE4_SELECTION_SPEC.md - Selection detaylı spec
5. docs/PHASE4_SHAPES_SPEC.md - Shapes detaylı spec
6. docs/PHASE4_PERFORMANCE_RULES.md - Performans kuralları

.cursorrules dosyası da güncellendi.

Her dökümanı oku ve bana şunları özetle:
1. Phase 4'ün 3 ana modülü nelerdir?
2. İlk modül (4A) kaç adımdan oluşuyor?
3. Hit testing için kritik performans kuralı nedir?

Dökümanları okumadan kod YAZMA.
```

---

## 📋 Phase 4A İlk Adım Komutu

Cursor dökümanları okuduktan sonra:

```
Tamam, Phase 4A-1'e başlayalım.

PHASE4_CURSOR_INSTRUCTIONS.md dosyasındaki ADIM 4A-1 görevini uygula.

📖 Referans: PHASE4_ERASER_SPEC.md - Hit Testing bölümü

⚠️ KURALLAR:
- Yeni klasör: packages/drawing_core/lib/src/hit_testing/
- Abstract class oluştur
- Barrel export ekle

Başla!
```

---

## 🔄 Her Adım Sonrası Cursor'dan Beklenti

```
📁 Dosyalar:
- packages/drawing_core/lib/src/hit_testing/hit_tester.dart (created)
- packages/drawing_core/lib/src/hit_testing/hit_testing.dart (created)

🧪 Testler:
- flutter analyze: ✅/❌
- flutter test: ✅ X test geçti

⚡ Performans Kontrolü (Phase 4 için):
- Bounds check kullanıldı: ✅/❌
- Path cached: ✅/❌
- Command batched: ✅/❌

📝 Commit önerisi:
feat(core): add hit testing infrastructure

Onay bekle.
```

---

## ⚠️ Phase 4 Kritik Hatırlatmalar

Her görevde Cursor'a ekle:

```
⚠️ PHASE 4 KURALLARI:

1. HIT TESTING: Mutlaka bounding box pre-filter kullan
2. SELECTION: Ayrı RepaintBoundary layer'da
3. SHAPES: Path'leri cache'le
4. COMMANDS: Gesture başına tek command (batching)

📖 Detaylar için: docs/PHASE4_PERFORMANCE_RULES.md
```

---

## 📊 Phase 4 İlerleme Takibi

### Phase 4A: Eraser (7 adım)
```
4A-1: ❌ Hit Testing Infrastructure
4A-2: ❌ StrokeHitTester
4A-3: ❌ EraserTool
4A-4: ❌ EraseStrokesCommand
4A-5: ❌ Eraser Provider
4A-6: ❌ Canvas Integration
4A-7: ❌ Test & Polish
```

### Phase 4B: Selection (9 adım)
```
4B-1: ❌ Selection Model
4B-2: ❌ SelectionTool Abstract
4B-3: ❌ LassoSelectionTool
4B-4: ❌ RectSelectionTool
4B-5: ❌ Selection Commands
4B-6: ❌ SelectionProvider
4B-7: ❌ SelectionPainter
4B-8: ❌ SelectionHandles
4B-9: ❌ Canvas Integration
```

### Phase 4C: Shapes (6 adım)
```
4C-1: ❌ Shape Model
4C-2: ❌ Layer Update
4C-3: ❌ Shape Tools
4C-4: ❌ Shape Commands
4C-5: ❌ ShapePainter
4C-6: ❌ Integration
```

---

## 🎯 Phase 4 Sonunda Hedefler

### Fonksiyonellik
- ✅ Silgi ile çizgi silme
- ✅ Lasso ile seçim yapma
- ✅ Dikdörtgen ile seçim yapma
- ✅ Seçimi taşıma/silme
- ✅ Düz çizgi çizme
- ✅ Dikdörtgen çizme
- ✅ Elips çizme
- ✅ Ok çizme

### Performans
- ✅ Hit test <5ms
- ✅ Selection 60 FPS
- ✅ Shape preview 60 FPS

### Kalite
- ✅ Full undo/redo support
- ✅ Clean architecture
- ✅ Comprehensive tests

---

## 📁 Dosya Yerleşimi

```
starnote_drawing_workspace/
├── .cursorrules                         ← DEĞİŞTİR
├── docs/
│   ├── CHECKLIST_TODO.md                ← DEĞİŞTİR
│   ├── PHASE4_MASTER_PLAN.md            ← YENİ
│   ├── PHASE4_CURSOR_INSTRUCTIONS.md    ← YENİ
│   ├── PHASE4_ERASER_SPEC.md            ← YENİ
│   ├── PHASE4_SELECTION_SPEC.md         ← YENİ
│   ├── PHASE4_SHAPES_SPEC.md            ← YENİ
│   ├── PHASE4_PERFORMANCE_RULES.md      ← YENİ
│   └── ... (mevcut dökümanlar)
└── packages/
```

---

## 🔧 Kopyalama Komutları

```bash
cd starnote_drawing_workspace

# .cursorrules güncelle
cp ~/Downloads/phase4/_cursorrules ./.cursorrules

# docs klasörüne kopyala
cp ~/Downloads/phase4/PHASE4_MASTER_PLAN.md ./docs/
cp ~/Downloads/phase4/PHASE4_CURSOR_INSTRUCTIONS.md ./docs/
cp ~/Downloads/phase4/PHASE4_ERASER_SPEC.md ./docs/
cp ~/Downloads/phase4/PHASE4_SELECTION_SPEC.md ./docs/
cp ~/Downloads/phase4/PHASE4_SHAPES_SPEC.md ./docs/
cp ~/Downloads/phase4/PHASE4_PERFORMANCE_RULES.md ./docs/
cp ~/Downloads/phase4/CHECKLIST_TODO.md ./docs/
```

---

## 💡 Tavsiyeler

### Modül Sırası (DEĞİŞTİRME!)
```
1. Phase 4A: Eraser    ← Hit testing altyapısı burada
2. Phase 4B: Selection ← Hit testing'i kullanır
3. Phase 4C: Shapes    ← En bağımsız modül
```

### Commit Stratejisi
- Her adım sonrası commit
- Her modül sonrası tag
- Modül tamamlanmadan merge YAPMA

### Test Stratejisi
- Her yeni class için test yaz
- Hit testing için benchmark test
- Selection için integration test

---

*İyi çalışmalar! Phase 4 başarıyla tamamlanacak! 🚀*
