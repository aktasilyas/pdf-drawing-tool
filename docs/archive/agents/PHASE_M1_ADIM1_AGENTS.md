# PHASE M1 — ADIM 1/5: ToolbarLayoutMode + Expanded Toolbar Refactor

## ÖZET
Responsive toolbar altyapısını kur. Mevcut ToolBar'ı koruyarak AdaptiveToolbar wrapper oluştur. Mevcut davranış değişmez — sadece yapısal hazırlık.

## BRANCH
```bash
git checkout -b feature/responsive-toolbar
```

---

## AGENT GÖREVLERİ

### 🏗️ @senior-architect — Mimari Onay (Bu adım zaten onaylı, skip edilebilir)

Bu adımın mimarisi yukarıda tanımlı. Flutter-developer direkt başlayabilir.

---

### 👨‍💻 @flutter-developer — İmplementasyon

**Görev:** 3 dosya oluştur, 3 dosya güncelle.

**1) YENİ DOSYA: `packages/drawing_ui/lib/src/toolbar/toolbar_layout_mode.dart`**

```dart
/// Toolbar display mode based on available screen width.
enum ToolbarLayoutMode {
  /// ≥840px — Full horizontal toolbar, all sections visible.
  expanded,

  /// 600-839px — Compact horizontal, overflow menu for extra tools.
  medium,

  /// <600px — Bottom bar with bottom sheet panels.
  compact,
}
```

**2) YENİ DOSYA: `packages/drawing_ui/lib/src/toolbar/adaptive_toolbar.dart`**

Mevcut ToolBar'ın tüm constructor parametrelerini alıp ToolBar'a delegate eden wrapper. Şimdilik sadece passthrough, ileride LayoutBuilder eklenecek. ToolBar'ın import'unu barrel export üzerinden yap: `import 'package:drawing_ui/drawing_ui.dart';` KULLANMA — circular dependency. Doğrudan relative import da yasak. Çözüm: aynı package içinde `package:drawing_ui/src/toolbar/tool_bar.dart` kullan.

**3) REFACTOR: `packages/drawing_ui/lib/src/toolbar/tool_bar.dart`**

Mevcut `_ToolBarState.build()` içindeki Container+Row layout kodunu `_buildExpandedLayout(...)` private metoduna extract et. Build metodu bu metodu çağırsın. Parametre olarak zaten build() içinde watch edilen değerleri geçir: `context, theme, canUndo, canRedo, currentTool, visibleTools, showQuickAccess`. Mevcut state logic (_onToolPressed, _onPanelTap vb.) dokunulmaz.

**4) GÜNCELLE: `packages/drawing_ui/lib/drawing_ui.dart`**

Toolbar bölümüne iki satır ekle:
```dart
export 'src/toolbar/toolbar_layout_mode.dart';
export 'src/toolbar/adaptive_toolbar.dart';
```

**5) GÜNCELLE: `packages/drawing_ui/lib/src/screens/drawing_screen.dart`**

`ToolBar(...)` → `AdaptiveToolbar(...)` değiştir. Import ekle. Parametreler aynı kalır.

**6) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- Max 300 satır/dosya
- Barrel exports zorunlu (yeni dosyalar eklendi)
- Hardcoded renk/spacing yasak
- Touch target min 48dp
- Mevcut ToolBar davranışı birebir korunmalı

---

### 🧪 @qa-engineer — Test

**Görev:** Mevcut testlerin geçtiğini doğrula + yeni testler ekle.

**1) Mevcut testleri çalıştır:**
```bash
cd packages/drawing_ui && flutter test
```
Tüm mevcut testler PASS olmalı. Özellikle `toolbar_test.dart` — regression yok.

**2) Yeni testler ekle: `packages/drawing_ui/test/toolbar_layout_mode_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/toolbar/toolbar_layout_mode.dart';

void main() {
  group('ToolbarLayoutMode', () {
    test('has exactly three modes', () {
      expect(ToolbarLayoutMode.values.length, 3);
    });

    test('contains expanded mode', () {
      expect(ToolbarLayoutMode.values, contains(ToolbarLayoutMode.expanded));
    });

    test('contains medium mode', () {
      expect(ToolbarLayoutMode.values, contains(ToolbarLayoutMode.medium));
    });

    test('contains compact mode', () {
      expect(ToolbarLayoutMode.values, contains(ToolbarLayoutMode.compact));
    });
  });
}
```

**3) AdaptiveToolbar widget testi ekle: `packages/drawing_ui/test/adaptive_toolbar_test.dart`**

AdaptiveToolbar'ı ProviderScope içinde pump et, undo/redo ikonlarının render edildiğini doğrula. Mevcut `toolbar_test.dart` setup'ını referans al (sharedPreferencesProvider override gerekli).

**4) Doğrulama:**
```bash
cd packages/drawing_ui && flutter test --coverage
```

---

### 🔍 @code-reviewer — Review

**Kontrol listesi:**
1. `toolbar_layout_mode.dart` — sadece enum, başka kod yok
2. `adaptive_toolbar.dart` — ToolBar'a clean passthrough, max 80 satır
3. `tool_bar.dart` — _buildExpandedLayout extract doğru yapılmış, mevcut logic bozulmamış
4. `drawing_screen.dart` — ToolBar → AdaptiveToolbar değişikliği, parametreler aynı
5. `drawing_ui.dart` — barrel exports eklendi
6. Relative import yok, hardcoded renk/spacing yok
7. `flutter analyze`: 0 error
8. Tüm testler pass

---

## COMMIT
```
feat(ui): add ToolbarLayoutMode enum and AdaptiveToolbar wrapper

- Create ToolbarLayoutMode enum (expanded/medium/compact)
- Create AdaptiveToolbar wrapper (delegates to ToolBar)
- Extract _buildExpandedLayout() from ToolBar.build()
- Update DrawingScreen to use AdaptiveToolbar
- Update barrel exports
- No regression: all existing tests pass
```

## SONRAKİ ADIM
Adım 2: LayoutBuilder + MediumToolbar (overflow menu, compact horizontal layout, 600-839px)
