# PHASE M4 — ADIM 2/4: Pen Settings Panel Popover Uyarlaması

## ÖZET
Mevcut PenSettingsPanel'i PopoverPanel içinde çalışacak şekilde uyarla. Daha kompakt, GoodNotes tarzı slider'lar (label + yüzde), stroke preview iyileştirmesi. Mevcut fonksiyonellik korunur.

## BRANCH
```bash
git checkout feature/pen-panel-modern
```

---

## MİMARİ KARAR

Mevcut PenSettingsPanel'i YIKIP YENİDEN YAZMA. Sadece popover'a uygun hale getir:
- ToolPanel wrapper'ı kaldır (popover zaten çerçeve sağlıyor)
- Padding'leri sıkıştır (16dp → 12dp)
- Mevcut _LiveStrokePreview, _PenTypeSelector, CompactSlider korunur
- GoodNotes tarzı slider formatı: "LABEL                    75%" + slider altında
- onClose callback kaldır (popover barrier ile kapanır)

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/panels/pen_settings_panel.dart — mevcut tam dosya
- packages/drawing_ui/lib/src/widgets/popover_panel.dart — yeni popover sistemi
- packages/drawing_ui/lib/src/widgets/compact_slider.dart — mevcut slider widget
- packages/drawing_ui/lib/src/widgets/pen_icon_widget.dart — kalem ikon widget
- packages/drawing_ui/lib/src/providers/drawing_providers.dart — penSettingsProvider, currentToolProvider
- packages/drawing_ui/lib/src/widgets/color_presets.dart — renk seçici

**1) GÜNCELLE: `pen_settings_panel.dart` — Popover uyumlu refactor**

Mevcut dosyayı refactor et. Yeni yapı:

```dart
/// Pen settings content for popover panel.
///
/// NOT wrapped in ToolPanel — designed to be placed inside PopoverPanel.
/// Contains: stroke preview, pen type selector, sliders, color, add to pen box.
class PenSettingsPanel extends ConsumerWidget {
  const PenSettingsPanel({
    super.key,
    required this.toolType,
  });

  // onClose KALDIRILDI — popover barrier ile kapanır

  final ToolType toolType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final activePenTool = _isPenTool(currentTool) ? currentTool : toolType;
    final settings = ref.watch(penSettingsProvider(activePenTool));
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12), // Daha sıkı padding
      child: Column(
        mainAxisSize: MainAxisSize.min, // Popover için önemli
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Başlık
          Text(
            _getTurkishTitle(activePenTool),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Live stroke preview (mevcut, height 50dp'ye çıkar)
          _LiveStrokePreview(
            color: settings.color,
            thickness: settings.thickness,
            toolType: activePenTool,
          ),
          const SizedBox(height: 12),

          // 3. Pen type selector (mevcut — ikon + label row)
          _PenTypeSelector(
            selectedType: currentTool,
            selectedColor: settings.color,
            onTypeSelected: (type) {
              ref.read(currentToolProvider.notifier).state = type;
            },
          ),
          const SizedBox(height: 12),

          // 4. Sliders — GoodNotes formatı
          _GoodNotesSlider(
            label: 'KALINLIK',
            value: settings.thickness.clamp(
              _getMinThickness(activePenTool),
              _getMaxThickness(activePenTool),
            ),
            min: _getMinThickness(activePenTool),
            max: _getMaxThickness(activePenTool),
            displayValue: '${settings.thickness.toStringAsFixed(1)}mm',
            activeColor: settings.color,
            onChanged: (value) {
              ref.read(penSettingsProvider(activePenTool).notifier)
                  .setThickness(value);
            },
          ),
          const SizedBox(height: 8),

          _GoodNotesSlider(
            label: 'SABİTLEME',
            value: settings.stabilization,
            min: 0.0,
            max: 1.0,
            displayValue: '${(settings.stabilization * 100).round()}%',
            activeColor: colorScheme.primary,
            onChanged: (value) {
              ref.read(penSettingsProvider(activePenTool).notifier)
                  .setStabilization(value);
            },
          ),
          const SizedBox(height: 12),

          // 5. Renk seçici (compact — 5 quick color + more butonu)
          _CompactColorSection(
            currentColor: settings.color,
            onColorChanged: (color) {
              ref.read(penSettingsProvider(activePenTool).notifier)
                  .setColor(color);
            },
          ),
          const SizedBox(height: 10),

          // 6. Kalem kutusuna ekle butonu
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _addToPenBox(context, ref, settings),
              icon: PhosphorIcon(StarNoteIcons.plus, size: 16),
              label: const Text(
                'Kalem kutusuna ekle',
                style: TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**2) YENİ WIDGET: `_GoodNotesSlider` — aynı dosyada**

GoodNotes tarzı slider: "LABEL" sol tarafta uppercase, "75%" sağ tarafta, slider altında.

```dart
class _GoodNotesSlider extends StatelessWidget {
  const _GoodNotesSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row: "KALINLIK                    0.3mm"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Slider
        SizedBox(
          height: 28, // Kompakt slider
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: activeColor,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: activeColor,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
```

**3) _LiveStrokePreview İYİLEŞTİRME**

Mevcut preview'u koru ama yüksekliği 28 → 50dp yap. Daha geniş sine wave, daha görünür.

```dart
// Değişiklik sadece height:
Container(
  width: double.infinity,
  height: 50, // 28'den 50'ye çıkarıldı
  ...
)
```

Ve _StrokePreviewPainter'da sine wave genliğini artır:

```dart
// Mevcut amplitude: size.height * 0.3
// Yeni: size.height * 0.35
```

**4) _PenTypeSelector İYİLEŞTİRME**

Mevcut yapıyı koru. Scrollable row olarak kalmalı. Her item:
- PenIconWidget (mevcut — zaten var ve güzel çalışıyor)
- Altında label text
- Selected: primary border

Eğer mevcut _PenTypeSelector çok büyükse, ikon boyutunu 56 → 44dp'ye küçült.

**5) _CompactColorSection — YENİ**

Popover içinde kompakt renk seçici. Mevcut ColorPresets widget'ını kullanabilir ama daha kompakt:

```dart
class _CompactColorSection extends StatelessWidget {
  const _CompactColorSection({
    required this.currentColor,
    required this.onColorChanged,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RENK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        // 5 quick colors + current color indicator + more button
        // Mevcut ColorPresets widget'ını compact modda kullan
        // veya inline row oluştur
        ColorPresets(
          selectedColor: currentColor,
          onColorSelected: onColorChanged,
          compact: true, // Eğer bu parametre yoksa, ekle veya inline row yap
        ),
      ],
    );
  }
}
```

Eğer ColorPresets `compact` parametresini desteklemiyorsa, inline row oluştur:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    for (final color in _quickColors)
      GestureDetector(
        onTap: () => onColorChanged(color),
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: color == currentColor
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: color == currentColor ? 2.5 : 1,
            ),
          ),
          child: color == currentColor
              ? Icon(Icons.check, size: 14, color: _contrastColor(color))
              : null,
        ),
      ),
    // "More" button
    GestureDetector(
      onTap: () => _showFullColorPicker(context),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: PhosphorIcon(
          StarNoteIcons.palette,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  ],
)
```

Quick colors: Siyah, Kırmızı, Mavi, Yeşil, Mor (veya mevcut renk listesinden ilk 5).

**6) ToolPanel wrapper'ı kaldırma**

Mevcut PenSettingsPanel ToolPanel wrapper içinde. Bu wrapper başlık + close butonu ekliyor. Popover'da buna gerek yok — popover barrier ile kapanır, başlık panel içinde.

Değişiklik: `ToolPanel(title:..., onClose:..., child: Column(...))` yerine direkt `Padding(padding: ..., child: Column(...))` kullan.

**7) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- pen_settings_panel.dart max 300 satır
- Mevcut fonksiyonellik KORUNMALI (pen type change, thickness, stabilization, color, add to penbox)
- ToolPanel wrapper kaldırılır (başlık + close → popover sağlar)
- _GoodNotesSlider: uppercase label + sağda değer + altta slider
- _LiveStrokePreview height 50dp
- _CompactColorSection: 5 quick color + more butonu
- Hardcoded renk yasak
- mainAxisSize: MainAxisSize.min zorunlu (popover yüksekliğini content belirler)

---

## COMMIT
```
feat(ui): refactor PenSettingsPanel for popover format

- Remove ToolPanel wrapper (popover provides frame)
- Add GoodNotes-style sliders (uppercase label + percentage)
- Stroke preview height 28→50dp
- Compact color section with 5 quick colors
- All functionality preserved
- Popover-ready with MainAxisSize.min
```

## SONRAKİ ADIM
Adım 3: Highlighter + Eraser Panel aynı formata uyarla
