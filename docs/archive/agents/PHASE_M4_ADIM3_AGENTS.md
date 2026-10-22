# PHASE M4 — ADIM 3/4: Tüm Tool Panel'leri Popover Formatına Uyarla

## ÖZET
PenSettingsPanel'e yapılan dönüşümü diğer panellere de uygula: ToolPanel wrapper kaldır, padding sıkıştır, _GoodNotesSlider formatına geç, onClose kaldır. Toplam 5 panel.

## BRANCH
```bash
git checkout feature/pen-panel-modern
```

---

## MİMARİ KARAR

Tüm panellerde aynı pattern:
1. ToolPanel wrapper → Padding(12dp) + Column(mainAxisSize: MainAxisSize.min)
2. onClose parametresi → kaldır
3. CompactSlider → _GoodNotesSlider (uppercase label + sağda değer)
4. Her panelin başına Text ile başlık ekle (fontSize: 15, fontWeight: w600)
5. import'tan ToolPanel kaldır

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/panels/pen_settings_panel.dart — REFERANS (zaten dönüştürüldü)
- packages/drawing_ui/lib/src/panels/highlighter_settings_panel.dart
- packages/drawing_ui/lib/src/panels/eraser_settings_panel.dart
- packages/drawing_ui/lib/src/panels/laser_pointer_panel.dart
- packages/drawing_ui/lib/src/panels/shapes_settings_panel.dart
- packages/drawing_ui/lib/src/screens/drawing_screen_panels.dart — panel oluşturma kodu

**PATTERN (pen_settings_panel'den kopyala):**

```dart
// ÖNCE:
class XxxPanel extends ConsumerWidget {
  const XxxPanel({super.key, this.onClose});
  final VoidCallback? onClose;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ToolPanel(
      title: 'Başlık',
      onClose: onClose,
      child: Column(
        children: [...],
      ),
    );
  }
}

// SONRA:
class XxxPanel extends ConsumerWidget {
  const XxxPanel({super.key});
  // onClose YOK
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Popover için kritik
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            'Başlık',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          // ... mevcut içerik (CompactSlider → _GoodNotesSlider)
        ],
      ),
    );
  }
}
```

---

**1) GÜNCELLE: `highlighter_settings_panel.dart`**

- ToolPanel wrapper kaldır → Padding(12) + Column(mainAxisSize.min)
- onClose kaldır
- Başlık: Text('Fosforlu Kalem' / 'Neon Fosforlu')
- CompactSlider'ları _GoodNotesSlider formatına çevir:
  - Kalınlık: label 'KALINLIK', displayValue '${thickness.toStringAsFixed(1)}mm'
  - Opaklık: label 'OPAKLIK', displayValue '${(opacity * 100).round()}%'
- Mevcut _HighlighterTypeSelector, _ThicknessBarPreview KORUNUR
- _GoodNotesSlider'ı pen_settings_panel'den buraya taşımak yerine ayrı shared widget yap VEYA her dosyada private tut

**_GoodNotesSlider shared yapma kararı:** Her dosyada private olarak tut (_GoodNotesSlider). Çünkü aynı widget, ama import cycle ve dosya bağımlılığı oluşmasın. İleride shared widget'a taşınabilir.

- import'tan ToolPanel kaldır
- Renk bölümü: mevcut _CompactHighlighterColors korunur

**2) GÜNCELLE: `eraser_settings_panel.dart`**

- ToolPanel wrapper kaldır → Padding(12) + Column(mainAxisSize.min)
- onClose kaldır
- Başlık: Text('Silgi')
- _CompactSizeSlider → _GoodNotesSlider formatı:
  - label 'BOYUT', displayValue '${size.round()}px'
- Mevcut _EraserModeSelector KORUNUR
- CompactToggle'lar KORUNUR (zaten kompakt)
- _CompactActionButton ('Sayfayı Temizle') KORUNUR
- import'tan ToolPanel kaldır

**3) GÜNCELLE: `laser_pointer_panel.dart`**

- ToolPanel wrapper kaldır → Padding(12) + Column(mainAxisSize.min)
- onClose kaldır
- Başlık: Text('Lazer işaretleyici')
- CompactSlider'ları _GoodNotesSlider formatına çevir:
  - Kalınlık: 'KALINLIK', '${thickness.toStringAsFixed(1)}mm'
  - Süre: 'SÜRE', '${duration.toStringAsFixed(1)}s'
- Mevcut _LaserModeSelector KORUNUR
- import'tan ToolPanel kaldır

**4) GÜNCELLE: `shapes_settings_panel.dart`**

- ToolPanel wrapper kaldır → Padding(12) + Column(mainAxisSize.min)
- onClose kaldır
- Başlık: Text('Şekil')
- CompactSlider → _GoodNotesSlider:
  - 'KONTUR KALINLIĞI', '${thickness.toStringAsFixed(1)}mm'
- Mevcut _ShapeGrid, _ColorSection, CompactToggle KORUNUR
- import'tan ToolPanel kaldır

**5) GÜNCELLE: Diğer paneller (varsa)**

Proje'de başka panel dosyaları varsa aynı pattern'ı uygula:
- lasso_selection_panel.dart
- sticker_panel.dart
- image_panel.dart
- ai_assistant_panel.dart
- toolbar_settings_panel.dart

Bu paneller için de: ToolPanel → Padding + Column, onClose kaldır. Ama bunlar daha az öncelikli — sadece ToolPanel wrapper'ı kaldır, slider formatını değiştirmeye gerek yok.

**6) GÜNCELLE: `drawing_screen_panels.dart`**

Tüm panel oluşturma yerlerinde onClose parametresini kaldır:

```dart
// ÖNCE:
HighlighterSettingsPanel(onClose: _closePanel)
EraserSettingsPanel(onClose: _closePanel)
LaserPointerPanel(onClose: _closePanel)
ShapesSettingsPanel(onClose: _closePanel)

// SONRA:
const HighlighterSettingsPanel()
const EraserSettingsPanel()
const LaserPointerPanel()
const ShapesSettingsPanel()
```

**7) GÜNCELLE: Test dosyaları**

Test'lerde onClose parametresini kaldır:
```bash
grep -rn "onClose" packages/drawing_ui/test/ --include="*.dart"
```
Bulunan referansları temizle.

**8) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- Her dosya max 300 satır
- _GoodNotesSlider her dosyada private (shared değil şimdilik)
- mainAxisSize: MainAxisSize.min HER panelde zorunlu
- Mevcut widget'lar (type selector, mode selector, grid, toggle) KORUNUR
- Sadece wrapper ve slider formatı değişiyor
- ToolPanel widget'ı SİLME — başka yerlerde kullanılıyor olabilir
- Hardcoded renk yasak

---

## COMMIT
```
feat(ui): convert all tool panels to popover format

- HighlighterSettingsPanel: remove ToolPanel, add GoodNotes sliders
- EraserSettingsPanel: remove ToolPanel, add GoodNotes sliders
- LaserPointerPanel: remove ToolPanel, add GoodNotes sliders
- ShapesSettingsPanel: remove ToolPanel, add GoodNotes sliders
- Remove onClose from all panels and callers
- All panels popover-ready with MainAxisSize.min
```

## SONRAKİ ADIM
Adım 4: DrawingScreen entegrasyonu — AnchoredPanel → PopoverPanel swap + test
