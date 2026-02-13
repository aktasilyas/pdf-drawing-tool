# PHASE M1 — ADIM 3/5: CompactBottomBar (Phone Layout)

## ÖZET
Telefon (<600px) için bottom bar oluştur. Toolbar ekranın altına taşınır, paneller bottom sheet olarak açılır. Canvas tam ekran kullanılır.

## BRANCH
```bash
git checkout feature/responsive-toolbar  # zaten bu branch'teyiz
```

---

## MİMARİ KARAR

Phone'da toolbar üstte yer kaplar ve canvas'ı daraltır. GoodNotes bile bunu tablet-only yapıyor. Bizim yaklaşım:

**Üst bar:** TopNavigationBar kalır ama compact versiyonu — sadece home + title + minimal actions
**Alt bar:** CompactBottomBar — undo/redo + aktif araç grubu (max 5) + more
**Paneller:** AnchoredPanel yerine showModalBottomSheet

```
Phone Layout (<600px):
┌──────────────────────────┐
│ ← Başlık           ⋯  📤 │  ← Compact TopNav (Row 1 sadeleştirilmiş)
├──────────────────────────┤
│                          │
│                          │
│       CANVAS AREA        │  ← Tam ekran canvas
│      (maximum space)     │
│                          │
│                          │
├──────────────────────────┤
│ [↶↷] [🖊][✏️][🖌][◇][⋯] │  ← CompactBottomBar
└──────────────────────────┘

Panel açıldığında (bottom sheet):
┌──────────────────────────┐
│       CANVAS AREA        │
├──────────────────────────┤
│ ┌──────────────────────┐ │
│ │ ━━━ (drag handle)    │ │
│ │ Dolma Kalem          │ │
│ │ [Kalem tipleri]      │ │
│ │ Kalınlık: ━━━●━━━    │ │
│ │ Renk: ●●●●●         │ │
│ └──────────────────────┘ │
├──────────────────────────┤
│ [↶↷] [🖊][✏️][🖌][◇][⋯] │
└──────────────────────────┘
```

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- docs/agents/GOODNOTES_UI_REFERENCE.md — UI referansı
- packages/drawing_ui/lib/src/toolbar/medium_toolbar.dart — Adım 2'de yapılan, pattern'ı takip et
- packages/drawing_ui/lib/src/toolbar/tool_bar.dart — mevcut expanded toolbar
- packages/drawing_ui/lib/src/screens/drawing_screen.dart — mevcut screen layout
- packages/drawing_ui/lib/src/screens/drawing_screen_panels.dart — buildActivePanel fonksiyonu

**1) YENİ DOSYA: `packages/drawing_ui/lib/src/toolbar/compact_bottom_bar.dart`**

Phone'da ekranın altında sabit bar. Max 250 satır.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';
import 'package:drawing_ui/src/toolbar/toolbar_overflow_menu.dart';

/// Compact bottom toolbar for phone screens (<600px).
///
/// Shows undo/redo + max 5 tool buttons + overflow menu.
/// Tool panels open as bottom sheets instead of anchored panels.
class CompactBottomBar extends ConsumerStatefulWidget {
  const CompactBottomBar({
    super.key,
    this.onUndoPressed,
    this.onRedoPressed,
    this.onToolPanelRequested,
  });

  final VoidCallback? onUndoPressed;
  final VoidCallback? onRedoPressed;

  /// Callback when a tool's panel should open as bottom sheet.
  /// DrawingScreen handles the actual showModalBottomSheet call.
  final ValueChanged<ToolType>? onToolPanelRequested;

  static const int maxVisibleTools = 5;
}

class _CompactBottomBarState extends ConsumerState<CompactBottomBar> {
  void _onToolPressed(ToolType tool) {
    final currentTool = ref.read(currentToolProvider);
    if (currentTool == tool) {
      // Aynı araca tekrar bas → panel aç
      widget.onToolPanelRequested?.call(tool);
    } else {
      ref.read(currentToolProvider.notifier).state = tool;
    }
  }

  void _onToolLongPress(ToolType tool) {
    widget.onToolPanelRequested?.call(tool);
  }

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final currentTool = ref.watch(currentToolProvider);
    final visibleTools = ref.watch(visibleToolsProvider);

    final shownTools = visibleTools.take(CompactBottomBar.maxVisibleTools).toList();
    final hiddenTools = visibleTools.skip(CompactBottomBar.maxVisibleTools).toList();

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const SizedBox(width: 8),

            // Undo/Redo
            ToolbarUndoRedoButtons(
              canUndo: canUndo,
              canRedo: canRedo,
              onUndo: widget.onUndoPressed,
              onRedo: widget.onRedoPressed,
            ),

            const SizedBox(width: 4),

            // Divider
            Container(
              width: 1,
              height: 28,
              color: colorScheme.outlineVariant,
            ),

            const SizedBox(width: 4),

            // Tool buttons (max 5)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: shownTools.map((tool) {
                  final isSelected = tool == currentTool;
                  return ToolButton(
                    toolType: tool,
                    isSelected: isSelected,
                    onPressed: () => _onToolPressed(tool),
                    onPanelTap: () => _onToolLongPress(tool),
                    hasPanel: true,
                  );
                }).toList(),
              ),
            ),

            // Overflow menu (if hidden tools exist)
            if (hiddenTools.isNotEmpty)
              ToolbarOverflowMenu(
                hiddenTools: hiddenTools,
                onToolSelected: (tool) {
                  ref.read(currentToolProvider.notifier).state = tool;
                },
              ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
```

**ÖNEMLİ TASARIM KARARLARI:**
- Bottom bar height: 56dp (Material standart)
- SafeArea bottom: iPhone home indicator'ı için
- Top border: ince çizgi ile canvas'tan ayırma
- Theme renkleri kullan: `colorScheme.surface`, `colorScheme.outlineVariant`
- Panel açma: `onToolPanelRequested` callback ile DrawingScreen'e delegate et — CompactBottomBar kendi başına bottom sheet açmaz

**2) YENİ DOSYA: `packages/drawing_ui/lib/src/toolbar/compact_tool_panel_sheet.dart`**

Bottom sheet wrapper — mevcut panel widget'larını bottom sheet içinde gösterir.

```dart
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';

/// Shows a tool's settings panel as a modal bottom sheet.
///
/// Wraps the existing panel widgets (PenSettingsPanel, EraserSettingsPanel, etc.)
/// inside a DraggableScrollableSheet for phone usage.
Future<void> showToolPanelSheet({
  required BuildContext context,
  required ToolType tool,
}) {
  // panZoom gibi panel'i olmayan araçlar için açma
  if (tool == ToolType.panZoom) return Future.value();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;

      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Panel content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: buildActivePanel(
                      panel: tool,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
```

**3) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/adaptive_toolbar.dart`**

LayoutBuilder'daki `< 600` case'ini güncelle. CompactBottomBar'ı döndürME — SizedBox.shrink() kalsın. Çünkü CompactBottomBar Scaffold.bottomNavigationBar'da veya Stack'te konumlandırılmalı, Column içinde değil.

Bunun yerine AdaptiveToolbar'a bir getter/static method ekle:

```dart
/// Returns true if compact mode should be used (phone layout).
/// When true, DrawingScreen should:
/// 1. Hide this toolbar (renders SizedBox.shrink)
/// 2. Show CompactBottomBar at bottom
/// 3. Use showToolPanelSheet for panels instead of AnchoredPanel
static bool shouldUseCompactMode(double width) => width < 600;
```

**4) GÜNCELLE: `packages/drawing_ui/lib/src/screens/drawing_screen.dart`**

Bu en kritik değişiklik. DrawingScreen'de phone layout'u entegre et:

```dart
// build() içinde:
final screenWidth = MediaQuery.of(context).size.width;
final isCompactMode = screenWidth < 600;
final isTabletOrDesktop = screenWidth >= 600;

// Scaffold'u güncelle:
Scaffold(
  backgroundColor: scaffoldBgColor,
  // Phone'da bottom bar ekle
  bottomNavigationBar: isCompactMode
      ? CompactBottomBar(
          onUndoPressed: _onUndoPressed,
          onRedoPressed: _onRedoPressed,
          onToolPanelRequested: (tool) {
            showToolPanelSheet(context: context, tool: tool);
          },
        )
      : null,
  body: SafeArea(
    child: Stack(
      children: [
        Column(
          children: [
            // Row 1: Top navigation (her zaman göster)
            TopNavigationBar(...),

            // Row 2: Toolbar (sadece tablet/desktop'ta)
            if (!isCompactMode)
              AdaptiveToolbar(...),

            // Canvas area
            Expanded(
              child: Row(
                children: [
                  // Sidebar (tablet only)
                  if (isTabletOrDesktop) ...[
                    // mevcut sidebar kodu
                  ],
                  // Canvas
                  Expanded(child: _buildCanvasArea(context, currentPage, transform)),
                ],
              ),
            ),
          ],
        ),

        // Panel overlay (sadece tablet/desktop — phone'da bottom sheet kullanılır)
        if (!isCompactMode) ...[
          // mevcut AnchoredPanel overlay kodu
        ],

        // Mobile sidebar overlay (mevcut kod aynen kalır)
        // ...
      ],
    ),
  ),
)
```

**ÖNEMLİ:** Phone modunda AnchoredPanel overlay'i GÖSTERME — paneller bottom sheet olarak açılıyor. Tablet/desktop'ta mevcut AnchoredPanel sistemi aynen korunur.

**5) GÜNCELLE: Barrel exports**

`packages/drawing_ui/lib/drawing_ui.dart`:
```dart
export 'src/toolbar/compact_bottom_bar.dart';
export 'src/toolbar/compact_tool_panel_sheet.dart';
```

`packages/drawing_ui/lib/src/toolbar/toolbar.dart`:
```dart
export 'compact_bottom_bar.dart';
export 'compact_tool_panel_sheet.dart';
```

**6) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- Max 300 satır/dosya
- Barrel exports zorunlu
- Hardcoded renk yasak — Theme.of(context).colorScheme kullan
- Bottom bar height: 56dp
- SafeArea kullan (bottom padding for iPhone)
- Touch target min 48dp
- Mevcut tablet/desktop davranışı HİÇ değişmemeli
- CompactBottomBar kendi başına bottom sheet açmaz — DrawingScreen'e callback ile bildirir

---

### 🧪 @qa-engineer — Test

**1) Mevcut testler:**
```bash
cd packages/drawing_ui && flutter test
```
Regression yok — tüm mevcut testler geçmeli.

**2) Yeni test: `packages/drawing_ui/test/compact_bottom_bar_test.dart`**

```dart
void main() {
  group('CompactBottomBar', () {
    testWidgets('renders undo/redo buttons', (tester) async {
      // Pump et, Icons.undo ve Icons.redo bul
    });

    testWidgets('shows max 5 tool buttons', (tester) async {
      // 10 visible tool varken max 5 tanesi görünmeli
    });

    testWidgets('shows overflow menu when tools > 5', (tester) async {
      // Icons.more_horiz bulunmalı
    });

    testWidgets('calls onToolPanelRequested on same tool tap', (tester) async {
      // Aktif tool'a tekrar basınca callback çağrılmalı
    });

    testWidgets('has correct height of 56', (tester) async {
      // Container height 56 olmalı
    });
  });
}
```

**3) Responsive integration test: `packages/drawing_ui/test/adaptive_toolbar_test.dart`** (güncelle)

```dart
testWidgets('shows CompactBottomBar at 400px via DrawingScreen', (tester) async {
  // 400px genişlikte DrawingScreen pump et
  // AdaptiveToolbar SizedBox.shrink olmalı
  // CompactBottomBar render edilmiş olmalı
});
```

---

### 🔍 @code-reviewer — Review

**Kontrol listesi:**
1. compact_bottom_bar.dart max 250 satır
2. compact_tool_panel_sheet.dart max 100 satır
3. Phone'da AnchoredPanel overlay gizlenmiş
4. Phone'da CompactBottomBar bottomNavigationBar'da
5. Tablet/desktop davranışı değişmemiş
6. SafeArea bottom padding var
7. DraggableScrollableSheet düzgün çalışıyor
8. Mevcut buildActivePanel reuse ediliyor
9. Hardcoded renk/spacing yok
10. flutter analyze: 0 error, tüm testler pass

---

## COMMIT
```
feat(ui): add CompactBottomBar for phone layout (<600px)

- Add CompactBottomBar: undo/redo + 5 tools + overflow at screen bottom
- Add showToolPanelSheet: tool panels as draggable bottom sheets
- Update DrawingScreen: compact mode with bottom bar + bottom sheet panels
- Hide AnchoredPanel overlay in compact mode
- Tablet/desktop behavior unchanged
- Update barrel exports
```

## SONRAKİ ADIM
Adım 4: DrawingScreen entegrasyon polish + TopNavigationBar compact modu + tablet test
