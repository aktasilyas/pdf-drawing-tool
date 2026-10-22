# PHASE M3 — ADIM 2/6: TopNavigationBar Profesyonelleştirme

## ÖZET
TopNavigationBar'daki tüm placeholder butonları temizle. Her buton ya çalışacak ya kaldırılacak. Yeni StarNoteNavButton widget'ı ile 48dp touch target, tutarlı stil.

## BRANCH
```bash
git checkout feature/toolbar-professional
```

---

## MİMARİ KARAR

Mevcut _showPlaceholder çağrıları:
- Okuyucu modu → Adım 4'te implement edilecek, şimdilik buton kalsın ama disabled göster
- Katmanlar → Placeholder kaldır, buton kalsın ama disabled göster (gelecek feature)
- Belge menüsü → Basit dropdown menü implement et (rename, duplicate, export)
- Ana Sayfa → Zaten çalışıyor (onHomePressed callback)

**NavButton yeniden tasarımı:**
Mevcut _NavButton 32x32dp, generic. Yeni StarNoteNavButton:
- 40x40dp tıklanabilir alan (48dp minimum padding ile)
- Hover/pressed feedback
- Active state gösterimi (arka plan tonu)
- Tooltip her zaman
- PhosphorIcon ile ElyanotesIcons kullanımı

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/toolbar/top_navigation_bar.dart — mevcut kodu incele
- docs/agents/goodnotes_01_toolbar_context_menu.jpeg — GoodNotes üst bar referansı
- docs/agents/goodnotes_04_readonly_mode.jpeg — minimal nav bar referansı

**1) REFACTOR: `top_navigation_bar.dart` — _NavButton → StarNoteNavButton**

Mevcut _NavButton'ı public widget olarak refactor et (diğer toolbar'larda da kullanılabilir):

```dart
/// Professional navigation button with consistent sizing and feedback.
class StarNoteNavButton extends StatelessWidget {
  const StarNoteNavButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.isDisabled = false,
    this.size = 36.0,
    this.iconSize,
    this.badge,
  });

  final PhosphorIconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isDisabled;
  final double size;
  final double? iconSize;
  final Widget? badge; // Opsiyonel badge (notification dot gibi)

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconSize = iconSize ?? ElyanotesIcons.navSize;

    final iconColor = isDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : isActive
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;

    final bgColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PhosphorIcon(
                  icon,
                  size: effectiveIconSize,
                  color: iconColor,
                ),
                if (badge != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: badge!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**2) REFACTOR: TopNavigationBar layout**

Mevcut layout'u yeniden düzenle. GoodNotes tarzı üç bölge:

```
Sol:  [Home] [Sidebar] [Başlık ▼]
Orta: <spacer>
Sağ:  [Okuyucu] [Katmanlar] [Grid] [Export] [More]
```

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final colorScheme = Theme.of(context).colorScheme;
  final gridVisible = ref.watch(gridVisibilityProvider);
  final pageCount = ref.watch(pageCountProvider);

  return Container(
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // ── Sol Bölge ──
          StarNoteNavButton(
            icon: ElyanotesIcons.home,
            tooltip: 'Ana Sayfa',
            onPressed: onHomePressed ?? () {},
          ),

          // Sidebar toggle (sadece çok sayfalı doküman)
          if (pageCount > 1)
            StarNoteNavButton(
              icon: ElyanotesIcons.sidebar,
              tooltip: 'Sayfa Paneli',
              onPressed: onSidebarToggle ?? () {},
              isActive: isSidebarOpen,
            ),

          const SizedBox(width: 4),

          // Doküman başlığı
          _buildDocumentTitle(context),

          // ── Orta Spacer ──
          const Expanded(child: SizedBox()),

          // ── Sağ Bölge ──
          
          // Okuyucu modu (Adım 4'te aktif edilecek)
          StarNoteNavButton(
            icon: ElyanotesIcons.readerMode,
            tooltip: 'Okuyucu Modu',
            onPressed: () => _toggleReaderMode(ref),
            isDisabled: true, // Adım 4'te enable edilecek
          ),

          // Grid toggle
          StarNoteNavButton(
            icon: gridVisible ? ElyanotesIcons.gridOn : ElyanotesIcons.gridOff,
            tooltip: gridVisible ? 'Kılavuzu Gizle' : 'Kılavuzu Göster',
            onPressed: () => ref.read(gridVisibilityProvider.notifier).state = !gridVisible,
            isActive: gridVisible,
          ),

          // Export/Share
          StarNoteNavButton(
            icon: ElyanotesIcons.export,
            tooltip: 'Dışa Aktar',
            onPressed: () => _showExportMenu(context, ref),
          ),

          // More menüsü
          StarNoteNavButton(
            icon: ElyanotesIcons.more,
            tooltip: 'Daha Fazla',
            onPressed: () => _showMoreMenu(context, ref),
          ),
        ],
      ),
    ),
  );
}
```

**3) YENİ: Export menüsü**

Mevcut PdfExportDialog zaten var. Share butonuna basınca popup menü göster:

```dart
void _showExportMenu(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(ElyanotesIcons.pdfFile, color: colorScheme.onSurface),
              title: const Text('PDF Olarak Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                showPdfExportDialog(context: context);
              },
            ),
            ListTile(
              leading: PhosphorIcon(ElyanotesIcons.image, color: colorScheme.onSurface),
              title: const Text('Resim Olarak Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Image export
              },
            ),
            ListTile(
              leading: PhosphorIcon(ElyanotesIcons.share, color: colorScheme.onSurface),
              title: const Text('Paylaş'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share
              },
            ),
          ],
        ),
      );
    },
  );
}
```

**4) YENİ: More menüsü**

```dart
void _showMoreMenu(BuildContext context, WidgetRef ref) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(ElyanotesIcons.template, color: colorScheme.onSurface),
              title: const Text('Şablon Değiştir'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Template change
              },
            ),
            ListTile(
              leading: PhosphorIcon(ElyanotesIcons.page, color: colorScheme.onSurface),
              title: const Text('Sayfa Ayarları'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Page settings
              },
            ),
            ListTile(
              leading: PhosphorIcon(ElyanotesIcons.sliders, color: colorScheme.onSurface),
              title: const Text('Belge Ayarları'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Document settings
              },
            ),
          ],
        ),
      );
    },
  );
}
```

**5) TopNavigationBar'a yeni callback'ler ekle:**

```dart
class TopNavigationBar extends ConsumerWidget {
  const TopNavigationBar({
    super.key,
    this.documentTitle,
    this.onHomePressed,
    this.onTitlePressed,
    this.onBackPressed,
    this.onSidebarToggle,    // YENİ
    this.isSidebarOpen = false, // YENİ
    this.compact = false,
  });

  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;
  final bool compact;
  // ... mevcut parametreler ...
}
```

**6) GÜNCELLE: drawing_screen.dart**

TopNavigationBar'a sidebar callback'lerini geçir:

```dart
TopNavigationBar(
  documentTitle: widget.documentTitle,
  onHomePressed: widget.onHomePressed,
  onTitlePressed: widget.onTitlePressed,
  onSidebarToggle: _toggleSidebar,
  isSidebarOpen: _isSidebarOpen,
  compact: isCompactMode,
),
```

**ÖNEMLİ:** Mevcut ToolBar'daki sidebar toggle butonu KALDIR — sidebar toggle artık TopNavigationBar'da. ToolBar'da showSidebarButton parametresini false yap veya kaldır.

**7) _showPlaceholder fonksiyonunu tamamen sil**

Kalan tüm `_showPlaceholder` çağrılarını kaldır. Gerçek fonksiyon yoksa disabled buton göster.

**8) Compact mode güncelle:**

```dart
// compact: true olduğunda (phone):
// Sol: Home + Başlık (kısaltılmış)
// Sağ: Export + More (sadece 2 buton)
// Okuyucu modu, grid, katmanlar gizli
```

**9) Barrel exports:**
StarNoteNavButton'ı export et (diğer widget'larda kullanılabilir):
```dart
// toolbar.dart barrel:
export 'starnote_nav_button.dart'; // eğer ayrı dosyaya çıkardıysan
```

Veya StarNoteNavButton'ı top_navigation_bar.dart içinde tut (tek dosyada) — max 300 satır kontrolü yap.

**10) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- _showPlaceholder tamamen silinmeli — 0 placeholder
- Her buton ya çalışır ya disabled
- StarNoteNavButton 36dp görsel + padding ile 48dp touch target
- Sidebar toggle TopNav'a taşındı, ToolBar'dan kaldırıldı
- Theme renkleri: colorScheme.* kullan
- top_navigation_bar.dart max 300 satır — aşarsa export/more menülerini ayrı dosyaya çıkar

---

### 🧪 @qa-engineer — Test

```dart
void main() {
  group('TopNavigationBar', () {
    testWidgets('home button present and tappable', ...);
    testWidgets('grid toggle changes state', ...);
    testWidgets('export button shows bottom sheet', ...);
    testWidgets('more button shows bottom sheet', ...);
    testWidgets('sidebar toggle shows when pageCount > 1', ...);
    testWidgets('compact mode shows minimal buttons', ...);
    testWidgets('no placeholder snackbars remain', ...);
  });
}
```

---

## COMMIT
```
feat(ui): professionalize TopNavigationBar with working buttons

- Replace _NavButton with StarNoteNavButton (36dp, hover/active states)
- Move sidebar toggle from ToolBar to TopNavigationBar
- Add export menu (PDF export, image export, share)
- Add more menu (template, page settings, document settings)
- Remove all _showPlaceholder calls — zero placeholders
- Compact mode for phone: minimal buttons
```

## SONRAKİ ADIM
Adım 3: ToolBar stil güncellemesi — tool button yeni stil, seçim gösterimi, QuickAccessRow iyileştirme
