# PHASE M3 — ADIM 3/6: ToolBar Stil Güncellemesi

## ÖZET
ToolButton yeni tasarım: seçili araç mavi pill/rounded arka plan (GoodNotes tarzı). QuickAccessRow renk daireleri büyütme, kalınlık gösterimi iyileştirme. Toolbar genel spacing ve padding polish.

## BRANCH
```bash
git checkout feature/toolbar-professional
```

---

## MİMARİ KARAR

GoodNotes'ta aktif araç seçimi: ikon etrafında yuvarlak mavi arka plan, ikon beyaza döner. Bizim mevcut seçim gösterimi: sadece renk değişikliği, arka plan vurgulama yok. Bu adımda GoodNotes tarzı seçim gösterimini implement ediyoruz.

QuickAccessRow'da renk daireleri küçük (20dp civarı). GoodNotes'ta 24-28dp ve border ile aktif renk gösterilir. Kalınlık gösterimi de çizgi preview olarak yapılabilir.

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/toolbar/tool_button.dart — mevcut ToolButton
- packages/drawing_ui/lib/src/toolbar/quick_access_row.dart — mevcut QuickAccessRow
- packages/drawing_ui/lib/src/toolbar/tool_bar.dart — mevcut ToolBar layout
- docs/agents/goodnotes_01_toolbar_context_menu.jpeg — GoodNotes Row 2 referansı
- docs/agents/goodnotes_03_pen_settings_panel.jpeg — GoodNotes ikon stilleri

**1) REFACTOR: `tool_button.dart` — Yeni ToolButton tasarımı**

GoodNotes tarzı: aktif araç = pill şeklinde arka plan + ikon renk değişimi.

```dart
class ToolButton extends ConsumerWidget {
  const ToolButton({
    super.key,
    required this.toolType,
    required this.isSelected,
    required this.onPressed,
    this.onPanelTap,
    this.hasPanel = false,
    this.buttonKey,
    this.compact = false, // Phone modunda daha küçük
  });

  final ToolType toolType;
  final bool isSelected;
  final VoidCallback onPressed;
  final VoidCallback? onPanelTap;
  final bool hasPanel;
  final GlobalKey? buttonKey;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final iconSize = compact ? 20.0 : ElyanotesIcons.toolSize;
    final buttonSize = compact ? 36.0 : 40.0;
    
    // GoodNotes tarzı seçim renkleri
    final backgroundColor = isSelected
        ? colorScheme.primary
        : Colors.transparent;
    final iconColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: toolType.displayName,
      child: GestureDetector(
        onTap: onPressed,
        onLongPress: hasPanel ? onPanelTap : null,
        child: Container(
          key: buttonKey,
          width: buttonSize,
          height: buttonSize,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: PhosphorIcon(
              ElyanotesIcons.iconForTool(toolType, active: isSelected),
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
```

**Ayrıca mevcut UndoButton, RedoButton, SettingsButton sınıfları varsa** bunları da aynı stile getir. Veya toolbar_widgets.dart'taki ToolbarUndoRedoButtons widget'ını güncelle:

```dart
// Undo/Redo butonları — disabled state ile:
PhosphorIcon(
  ElyanotesIcons.undo,
  size: ElyanotesIcons.actionSize,
  color: canUndo 
      ? colorScheme.onSurfaceVariant 
      : colorScheme.onSurface.withValues(alpha: 0.25),
)
```

**2) REFACTOR: `quick_access_row.dart` — Renk daireleri ve kalınlık**

Renk daireleri:
- Boyut: 24dp (mevcut 20dp'den büyütme)
- Aktif renk: 2dp beyaz border + gölge
- Seçili renk: checkmark overlay
- Daha belirgin spacing

```dart
/// Single color chip in quick access row.
class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : color.computeLuminance() > 0.8
                    ? Theme.of(context).colorScheme.outlineVariant
                    : Colors.transparent,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                )]
              : null,
        ),
        child: isSelected
            ? Center(
                child: PhosphorIcon(
                  ElyanotesIcons.check,
                  size: 12,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}
```

Kalınlık gösterimi:
- Mevcut nokta yerine küçük yatay çizgi preview (gerçek kalınlığı temsil eder)
- Seçili kalınlık: primary renk border

```dart
/// Single thickness indicator in quick access row.
class _ThicknessChip extends StatelessWidget {
  const _ThicknessChip({
    required this.thickness,
    required this.isSelected,
    required this.onTap,
    required this.currentColor,
  });

  final double thickness;
  final bool isSelected;
  final VoidCallback onTap;
  final Color currentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Kalınlığı 1-6dp arası görsel çizgiye eşle
    final visualThickness = (thickness * 0.8).clamp(1.0, 6.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: visualThickness,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(visualThickness / 2),
            ),
          ),
        ),
      ),
    );
  }
}
```

**3) GÜNCELLE: `tool_bar.dart` — Genel spacing ve padding**

Toolbar container iyileştirmesi:
- Height: 48dp (mevcut 46dp → standart 48dp)
- Tool button'lar arası spacing: 2dp margin (tool_button.dart'ta)
- Divider: daha ince ve subtle
- QuickAccessRow ve tool butonları arasında net divider

```dart
Container(
  height: 48,
  decoration: BoxDecoration(
    color: colorScheme.surface,
    border: Border(
      bottom: BorderSide(
        color: colorScheme.outlineVariant,
        width: 0.5,
      ),
    ),
  ),
  // ... Row children ...
)
```

**4) GÜNCELLE: `medium_toolbar.dart` ve `compact_bottom_bar.dart`**

Aynı ToolButton stili bu toolbar'larda da geçerli olacak — ToolButton widget'ı zaten ortak kullanılıyor, değişiklik otomatik yansır. Sadece spacing/padding kontrol et.

**5) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- ToolButton: seçili = primary renk arka plan, ikon onPrimary
- ToolButton: deselected = transparent arka plan, ikon onSurfaceVariant
- Renk daireleri: 24dp, seçili = primary border + checkmark
- Kalınlık: çizgi preview, seçili = primary border
- Toolbar height: 48dp
- Hardcoded renk yasak — colorScheme.* kullan
- tool_button.dart max 150 satır
- quick_access_row.dart max 300 satır

---

### 🧪 @qa-engineer — Test

```dart
void main() {
  group('ToolButton new style', () {
    testWidgets('selected tool has primary background', ...);
    testWidgets('deselected tool has transparent background', ...);
    testWidgets('compact mode uses smaller size', ...);
  });

  group('QuickAccessRow', () {
    testWidgets('color chips render with correct size', ...);
    testWidgets('selected color has border and checkmark', ...);
    testWidgets('thickness chips show line preview', ...);
  });
}
```

---

## COMMIT
```
feat(ui): redesign ToolButton with GoodNotes-style selection + polish QuickAccessRow

- ToolButton: selected = primary bg + onPrimary icon (pill shape)
- Color chips: 24dp with selection border + checkmark
- Thickness chips: line preview with selection border
- Toolbar height standardized to 48dp
- Consistent spacing across all toolbar variants
```

## SONRAKİ ADIM
Adım 4: Okuyucu Modu (Read-Only Mode)
