# PHASE M4 — ADIM 4/4: DrawingScreen Entegrasyonu + PopoverPanel Swap

## ÖZET
AnchoredPanelController → PopoverController swap. Tüm tool panelleri artık popover olarak açılır. Test ve commit.

## BRANCH
```bash
git checkout feature/pen-panel-modern
```

---

## MİMARİ KARAR

Swap basit: `handlePanelChange` fonksiyonundaki `AnchoredPanelController` → `PopoverController` değişir. API neredeyse aynı:

```
AnchoredPanelController.show(context, anchorKey, child, onBarrierTap, alignment, verticalOffset)
→
PopoverController.show(context, anchorKey, child, onDismiss, maxWidth)
```

Farklar:
- PopoverController'da `alignment` yok (otomatik center + clamp)
- PopoverController'da `verticalOffset` yok (sabit 4dp)
- PopoverController'da `onBarrierTap` → `onDismiss`
- PopoverController'da `maxWidth` default 280dp

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/screens/drawing_screen_layout.dart — handlePanelChange fonksiyonu (ANA DEĞİŞİKLİK)
- packages/drawing_ui/lib/src/screens/drawing_screen.dart — panelController tanımı
- packages/drawing_ui/lib/src/widgets/popover_panel.dart — PopoverController API
- packages/drawing_ui/lib/src/widgets/anchored_panel.dart — AnchoredPanelController (eski)

**1) GÜNCELLE: `drawing_screen.dart` — Controller değişimi**

```dart
// ÖNCE:
final AnchoredPanelController _panelController = AnchoredPanelController();

// SONRA:
final PopoverController _panelController = PopoverController();
```

Import güncelle:
```dart
// Ekle (eğer yoksa):
import 'package:drawing_ui/src/widgets/popover_panel.dart';
// AnchoredPanelController import'u kalabilir (başka yerde kullanılıyorsa)
```

dispose() içinde:
```dart
_panelController.dispose(); // Aynı kalır — PopoverController da dispose() var
```

**2) GÜNCELLE: `drawing_screen_layout.dart` — handlePanelChange**

```dart
// ÖNCE:
void handlePanelChange({
  required BuildContext context,
  required ToolType? panel,
  required AnchoredPanelController panelController,
  required Map<ToolType, GlobalKey> toolButtonKeys,
  required GlobalKey penGroupButtonKey,
  required GlobalKey highlighterGroupButtonKey,
  required GlobalKey settingsButtonKey,
  required VoidCallback onClosePanel,
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
        alignment: resolvePanelAlignment(panel),
        verticalOffset: 8,
        onBarrierTap: onClosePanel,
        child: buildActivePanel(panel: panel, onClose: onClosePanel),
      );
    });
  }
}

// SONRA:
void handlePanelChange({
  required BuildContext context,
  required ToolType? panel,
  required PopoverController panelController,
  required Map<ToolType, GlobalKey> toolButtonKeys,
  required GlobalKey penGroupButtonKey,
  required GlobalKey highlighterGroupButtonKey,
  required GlobalKey settingsButtonKey,
  required VoidCallback onClosePanel,
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
        child: buildActivePanel(panel: panel),
      );
    });
  }
}
```

Değişiklikler:
- `AnchoredPanelController` → `PopoverController` (parametre tipi)
- `alignment` parametresi kaldırıldı (PopoverController otomatik center)
- `verticalOffset` kaldırıldı (PopoverController sabit)
- `onBarrierTap` → `onDismiss`
- `buildActivePanel` çağrısından `onClose: onClosePanel` kaldırıldı (paneller artık onClose almıyor)

**3) GÜNCELLE: `drawing_screen_panels.dart` — buildActivePanel**

Eğer `buildActivePanel` fonksiyonu `onClose` parametresi alıyorsa kaldır:

```dart
// ÖNCE:
Widget buildActivePanel({required ToolType panel, VoidCallback? onClose}) { ... }

// SONRA:
Widget buildActivePanel({required ToolType panel}) { ... }
```

Panel oluşturma yerlerinde onClose zaten Adım 3'te kaldırıldı.

**4) GÜNCELLE: `resolvePanelAlignment` fonksiyonunu kaldır veya deprecate et**

PopoverController alignment almadığı için bu fonksiyon artık gereksiz. Eğer başka yerde kullanılmıyorsa kaldır. Kullanılıyorsa bırak.

**5) Import güncellemeleri**

```dart
// drawing_screen_layout.dart:
// Ekle:
import 'package:drawing_ui/src/widgets/popover_panel.dart';
// AnchoredPanelController import'u KALDIR (eğer sadece burada kullanılıyorsa)

// drawing_screen.dart:
// Ekle:
import 'package:drawing_ui/src/widgets/popover_panel.dart';
```

**6) `buildActivePanel`'de panel onClose'un tamamen temizlendiğini doğrula**

```bash
grep -rn "onClose" packages/drawing_ui/lib/src/screens/drawing_screen_panels.dart
```

Hiç onClose referansı kalmamalı.

**7) Doğrulama — sadece analyze:**
```bash
cd packages/drawing_ui && dart analyze
```

Test çalıştırma — İlyas hata olursa bildirecek.

**KURALLAR:**
- PopoverController API'si kullan (show/hide/dispose)
- alignment ve verticalOffset KALDIRILDI (PopoverController bunları otomatik yönetiyor)
- Mevcut anchor key logic KORUNUR (penGroupButtonKey, highlighterGroupButtonKey, settingsButtonKey pattern)
- Compact mode (<600px) check KORUNUR
- AnchoredPanelController import'u kaldırılabilir (eğer başka yerde yoksa)
- AnchoredPanel dosyası SİLME (backward compat)

---

## COMMIT
```
feat(ui): swap AnchoredPanel → PopoverPanel for tool settings

- Replace AnchoredPanelController with PopoverController
- Animated popover with arrow pointing to toolbar button
- Remove alignment/verticalOffset params (auto-positioned)
- All tool panels open as compact popovers
- AnchoredPanel kept for backward compatibility
```

## MERGE
```bash
git checkout main
git merge feature/pen-panel-modern
git branch -d feature/pen-panel-modern
```

Push Windows PowerShell'den.

## M4 PHASE TAMAMLANDI ✅

### Eklenen/Değişen:
1. **PopoverPanel** — Yeni animasyonlu popover widget (280dp, scale+fade, arrow)
2. **PenSettingsPanel** — GoodNotes tarzı: stroke preview 50dp, uppercase label slider'lar, compact renk
3. **HighlighterSettingsPanel** — Aynı popover formatı
4. **EraserSettingsPanel** — Aynı popover formatı
5. **LaserPointerPanel** — Aynı popover formatı
6. **ShapesSettingsPanel** — Aynı popover formatı
7. **Tüm paneller** — ToolPanel wrapper kaldırıldı, onClose kaldırıldı
8. **DrawingScreen** — PopoverController entegrasyonu
