# PHASE M4B — İki Adımlı Kalem Popover Sistemi

## ÖZET
Kalem butonuna tap → küçük popover (kalem listesi). Kaleme tap → picker kapanır, ayar paneli popover açılır.

## BRANCH
```bash
git checkout -b feature/pen-type-picker
```

---

## AKIŞ

```
Toolbar: [🖊️ Kalem]  [🖍 Fosforlu]  [⬜ Silgi]  ...
              │
         tek tap
              ↓
┌──────────────────────┐
│  🖋️ Dolma Kalem      │  ← seçili (vurgulu)
│  ✒️ Tükenmez Kalem   │
│  ✏️ Kurşun Kalem     │
│  🖌️ Fırça Kalem      │
│  🔵 Jel Kalem        │
│  ┈┈ Kesikli Kalem    │
└──────────────────────┘
         △
      tap "Fırça"
         ↓
  picker kapanır → ayar paneli açılır
         ↓
┌─────────────────────────────┐
│  Fırça Kalem                │
│  ~~~~~~ preview ~~~~~~      │
│  🖋️ Dolma  ✒️ Tük  🖌️ Fır │
│  KALINLIK          5.0mm   │
│  ════════●════              │
│  STABİLİZASYON      30%   │
│  ═══●════════               │
│  RENK  [⚫][🔴][🔵][⊕]    │
│  [ Kalem kutusuna ekle ]    │
└─────────────────────────────┘
         △

Long press kalem → direkt ayar paneli (picker atlanır)
```

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer

**Önce oku:**
1. packages/drawing_ui/lib/src/toolbar/tool_bar.dart — _onToolPressed, _onPanelTap, _isPen
2. packages/drawing_ui/lib/src/toolbar/medium_toolbar.dart — aynı fonksiyonlar
3. packages/drawing_ui/lib/src/screens/drawing_screen_panels.dart — buildActivePanel
4. packages/drawing_ui/lib/src/screens/drawing_screen_layout.dart — handlePanelChange
5. packages/drawing_ui/lib/src/screens/drawing_screen.dart — panelController, _closePanel
6. packages/drawing_ui/lib/src/widgets/popover_panel.dart — PopoverController
7. packages/drawing_ui/lib/src/toolbar/tool_groups.dart — penTools, penToolsSet
8. packages/drawing_ui/lib/src/widgets/pen_icon_widget.dart — ToolPenIcon

---

**ADIM 1: Yeni provider — `pen_picker_mode_provider.dart`**

Dosya: `packages/drawing_ui/lib/src/providers/pen_picker_mode_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, pen group button opens PenTypePicker instead of PenSettingsPanel.
final penPickerModeProvider = StateProvider<bool>((ref) => false);
```

Barrel export: `providers.dart` → `export 'pen_picker_mode_provider.dart';`

---

**ADIM 2: Yeni widget — `pen_type_picker.dart`**

Dosya: `packages/drawing_ui/lib/src/panels/pen_type_picker.dart` (max 100 satır)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';

/// Compact pen type picker — first-level popover.
/// Shows list of pen types. Tap → selects pen, triggers onPenSelected callback.
class PenTypePicker extends ConsumerWidget {
  const PenTypePicker({super.key, this.onPenSelected});

  final ValueChanged<ToolType>? onPenSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: penTools.map((pen) {
          final isSelected = pen == currentTool;
          final config = pen.penType?.config;
          final label = config?.displayNameTr ?? pen.displayName;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(currentToolProvider.notifier).state = pen;
                onPenSelected?.call(pen);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Kalem ikonu
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: ToolPenIcon(
                        toolType: pen,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        isSelected: isSelected,
                        size: 24,
                        orientation: PenOrientation.vertical,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Kalem adı
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Seçili gösterge
                    if (isSelected)
                      Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

Barrel export: `panels/panels.dart` veya uygun barrel → `export 'pen_type_picker.dart';`

---

**ADIM 3: tool_bar.dart — pen group tap davranışını değiştir**

`_onToolPressed` metodunda pen group için yeni davranış:

```dart
void _onToolPressed(ToolType tool) {
  final currentTool = ref.read(currentToolProvider);

  // Pen group'a tap → picker aç
  if (_isPen(tool)) {
    final activePanel = ref.read(activePanelProvider);
    // Eğer bu kalem zaten aktif tool ve panel açıksa → kapat
    if (_isPen(currentTool) && penToolsSet.contains(activePanel)) {
      ref.read(activePanelProvider.notifier).state = null;
      ref.read(penPickerModeProvider.notifier).state = false;
      return;
    }
    // Kalemi seç (eğer farklıysa)
    if (currentTool != tool) {
      ref.read(currentToolProvider.notifier).state = tool;
    }
    // Picker mode aç
    ref.read(penPickerModeProvider.notifier).state = true;
    ref.read(activePanelProvider.notifier).state = tool;
    return;
  }

  // Mevcut davranış — diğer araçlar
  ref.read(currentToolProvider.notifier).state = tool;
  ref.read(activePanelProvider.notifier).state = null;
}
```

`_onPanelTap` (long press / chevron) — direkt ayar paneli:

```dart
void _onPanelTap(ToolType tool) {
  final activePanel = ref.read(activePanelProvider);
  if (activePanel == tool) {
    ref.read(activePanelProvider.notifier).state = null;
    ref.read(penPickerModeProvider.notifier).state = false;
  } else {
    // Long press: picker'ı atla, direkt settings
    ref.read(penPickerModeProvider.notifier).state = false;
    ref.read(activePanelProvider.notifier).state = tool;
  }
}
```

Import ekle: `penPickerModeProvider` kullanabilmek için providers import'u olmalı (zaten var olabilir).

---

**ADIM 4: medium_toolbar.dart — aynı değişiklik**

medium_toolbar.dart'ta da `_onToolPressed` ve `_onPanelTap` fonksiyonları var. Aynı pen group logic'ini uygula (tool_bar.dart ile aynı pattern).

---

**ADIM 5: compact_bottom_bar.dart — aynı değişiklik**

compact_bottom_bar.dart'ta da `_onToolPressed` ve `_onPanelTap` var. Aynı pattern.

---

**ADIM 6: drawing_screen_panels.dart — buildActivePanel güncelle**

buildActivePanel fonksiyonuna `isPenPickerMode` ve `onPenSelected` parametreleri ekle:

```dart
Widget buildActivePanel({
  required ToolType panel,
  bool isPenPickerMode = false,
  ValueChanged<ToolType>? onPenSelected,
}) {
  // Pen picker mode — küçük kalem listesi
  if (isPenPickerMode && penToolsSet.contains(panel)) {
    return PenTypePicker(onPenSelected: onPenSelected);
  }

  // Normal panel logic — mevcut switch/if devam eder
  if (penToolsSet.contains(panel)) {
    return PenSettingsPanel(toolType: panel);
  }
  // ... diğer paneller (highlighter, eraser, etc.) aynen kalır
}
```

Import ekle: `import '...panels/pen_type_picker.dart';` veya barrel'dan.

---

**ADIM 7: drawing_screen_layout.dart — handlePanelChange güncelle**

Parametre ekle ve buildActivePanel çağrısını güncelle:

```dart
void handlePanelChange({
  required BuildContext context,
  required ToolType? panel,
  required PopoverController panelController,
  required Map<ToolType, GlobalKey> toolButtonKeys,
  required GlobalKey penGroupButtonKey,
  required GlobalKey highlighterGroupButtonKey,
  required GlobalKey settingsButtonKey,
  required VoidCallback onClosePanel,
  bool isPenPickerMode = false,                   // YENİ
  ValueChanged<ToolType>? onPenSelected,           // YENİ
}) {
  if (MediaQuery.of(context).size.width < ToolbarLayoutMode.compactBreakpoint) return;
  if (panel == null) {
    panelController.hide();
  } else if (panel != ToolType.panZoom) {
    final anchorKey = panel == ToolType.toolbarSettings
        ? settingsButtonKey
        : penToolsSet.contains(panel)
            ? penGroupButtonKey
            : highlighterToolsSet.contains(panel)
                ? highlighterGroupButtonKey
                : toolButtonKeys[panel] ?? GlobalKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      panelController.show(
        context: context,
        anchorKey: anchorKey,
        onDismiss: onClosePanel,
        maxWidth: isPenPickerMode && penToolsSet.contains(panel) ? 220 : 280, // Picker daha dar
        child: buildActivePanel(
          panel: panel,
          isPenPickerMode: isPenPickerMode,
          onPenSelected: onPenSelected,
        ),
      );
    });
  }
}
```

Picker popover daha dar: `maxWidth: 220` (sadece liste). Settings popover: `maxWidth: 280` (mevcut).

---

**ADIM 8: drawing_screen.dart — provider watch + callback**

`build()` veya panel listener'da:

```dart
final isPenPickerMode = ref.watch(penPickerModeProvider);
```

handlePanelChange çağrısında:

```dart
handlePanelChange(
  // ... mevcut parametreler ...
  isPenPickerMode: isPenPickerMode,
  onPenSelected: (selectedPen) {
    // 1. Picker mode kapat
    ref.read(penPickerModeProvider.notifier).state = false;
    // 2. Popover kapat
    ref.read(activePanelProvider.notifier).state = null;
    // 3. Kısa gecikme ile ayar paneli aç (yeni popover)
    Future.microtask(() {
      ref.read(activePanelProvider.notifier).state = selectedPen;
    });
  },
);
```

---

**ADIM 9: Panel kapatma temizliği**

`_closePanel` veya eşdeğer fonksiyonda penPickerMode'u da resetle:

```dart
void _closePanel() {
  ref.read(activePanelProvider.notifier).state = null;
  ref.read(penPickerModeProvider.notifier).state = false;
}
```

Bu fonksiyon `onClosePanel` callback olarak handlePanelChange'e geçiyor. Mevcut `_closePanel` fonksiyonunu bul ve penPickerModeProvider reset'i ekle.

---

**ADIM 10: dart analyze**

```bash
cd packages/drawing_ui && dart analyze
```

Flutter test ÇALIŞTIRMA.

---

## KURALLAR
- pen_type_picker.dart max 100 satır
- pen_picker_mode_provider.dart max 10 satır
- PenTypePicker: liste formatı (ikon sol + label sağ + check), InkWell ripple
- Seçili kalem: primaryContainer bg + primary renk text + check ikonu
- Picker popover maxWidth: 220dp (dar)
- Settings popover maxWidth: 280dp (mevcut)
- Tap pen → picker aç | Long press → direkt settings | Picker'da tap → settings aç
- Panel kapatma penPickerMode'u resetler
- Mevcut highlighter, eraser, shapes vb. panel davranışı DEĞİŞMEZ
- Hardcoded renk YASAK

---

## COMMIT
```
feat(ui): add two-level pen popover — PenTypePicker → PenSettingsPanel

- New PenTypePicker: compact pen list with icon + label
- Tap toolbar pen → picker popover (220dp)
- Tap pen in picker → settings popover (280dp)
- Long press → direct settings (skip picker)
- penPickerModeProvider for state management
```

## MERGE
```bash
git checkout main && git merge feature/pen-type-picker && git branch -d feature/pen-type-picker
```
