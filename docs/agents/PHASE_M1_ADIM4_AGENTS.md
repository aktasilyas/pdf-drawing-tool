# PHASE M1 — ADIM 4/5: DrawingScreen Split + TopNav Compact + Polish

## ÖZET
drawing_screen.dart 729 satır — max 300 kuralını aşıyor. Responsive logic'i ayrı dosyalara çıkar. TopNavigationBar'a compact mode ekle. Phone/tablet geçişlerini polish et.

## BRANCH
```bash
git checkout feature/responsive-toolbar  # zaten bu branch'teyiz
```

---

## GÖREVLER

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/screens/drawing_screen.dart — 729 satır, split edilecek
- packages/drawing_ui/lib/src/screens/drawing_screen_panels.dart — mevcut panel helpers
- packages/drawing_ui/lib/src/toolbar/top_navigation_bar.dart — compact mode eklenecek
- docs/agents/goodnotes_04_readonly_mode.jpeg — GoodNotes minimal üst bar referansı

**1) SPLIT: drawing_screen.dart → drawing_screen_layout.dart**

drawing_screen.dart'tan responsive layout logic'ini ayır. Hedef: drawing_screen.dart max 300 satır.

Yeni dosya: `packages/drawing_ui/lib/src/screens/drawing_screen_layout.dart`

Bu dosyaya taşınacak kodlar:
- `_buildCanvasArea()` metodu
- `_buildSidebar()` metodu
- Sidebar ile ilgili state ve animasyon logic'i (_isSidebarOpen, _toggleSidebar, _closeSidebar)
- Mobile backdrop + animated sidebar overlay kodu

Yaklaşım: Mixin kullan. DrawingScreen _DrawingScreenState'e mixin olarak layout helper'ları ekle.

```dart
/// Layout helpers for DrawingScreen responsive behavior.
mixin DrawingScreenLayoutMixin<T extends StatefulWidget> on State<T> {
  // Sidebar state
  bool get isSidebarOpen;
  set isSidebarOpen(bool value);

  // Layout builders
  Widget buildCanvasArea(BuildContext context, ...);
  Widget buildSidebar();
  Widget buildMobileSidebarOverlay();
  Widget buildTabletSidebar(bool showSidebar);
}
```

Veya daha basit: helper fonksiyonları ayrı dosyaya static/top-level fonksiyon olarak çıkar ve DrawingScreen build() içinden çağır.

**En basit yaklaşım:** Mevcut drawing_screen_panels.dart pattern'ını takip et — top-level helper fonksiyonlar.

```dart
// drawing_screen_layout.dart

/// Build canvas area with background, drawing canvas, and overlays.
Widget buildDrawingCanvasArea({
  required BuildContext context,
  required WidgetRef ref,
  required int currentPage,
  required Matrix4 transform,
  required bool isCompactMode,
  // ... diğer gerekli parametreler
}) {
  // Mevcut _buildCanvasArea kodu buraya
}

/// Build page sidebar for tablet layout.
Widget buildPageSidebar({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onPageTap,
}) {
  // Mevcut _buildSidebar kodu buraya
}
```

**2) GÜNCELLE: `packages/drawing_ui/lib/src/toolbar/top_navigation_bar.dart`**

Compact mode ekle. Phone'da daha az buton göster.

```dart
class TopNavigationBar extends ConsumerWidget {
  const TopNavigationBar({
    super.key,
    this.documentTitle,
    this.onHomePressed,
    this.onTitlePressed,
    this.compact = false,  // YENİ parametre
  });

  /// When true, shows minimal layout for phone screens.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return _buildCompactNav(context, ref);
    }
    return _buildFullNav(context, ref);
  }

  Widget _buildCompactNav(BuildContext context, WidgetRef ref) {
    // Sadece: ← Home | Başlık (truncated) | Share | More(...)
    // Kamera, crop, mic gibi butonlar gizli
  }

  Widget _buildFullNav(BuildContext context, WidgetRef ref) {
    // Mevcut full navigation bar kodu (değişiklik yok)
  }
}
```

**3) GÜNCELLE: drawing_screen.dart — compact TopNav kullan**

```dart
TopNavigationBar(
  documentTitle: widget.documentTitle,
  onHomePressed: widget.onHomePressed,
  onTitlePressed: widget.onTitlePressed,
  compact: isCompactMode,  // Phone'da compact
),
```

**4) GÜNCELLE: drawing_screen.dart — layout helpers kullan**

_buildCanvasArea ve _buildSidebar çağrılarını drawing_screen_layout.dart'taki fonksiyonlarla değiştir. drawing_screen.dart 300 satırın altına inmeli.

**5) Barrel exports güncelle**

`packages/drawing_ui/lib/drawing_ui.dart`:
```dart
export 'src/screens/drawing_screen_layout.dart';
```

**6) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- drawing_screen.dart → max 300 satır
- drawing_screen_layout.dart → max 300 satır
- top_navigation_bar.dart → compact mode eklendikten sonra max 300 satır
- Mevcut davranış korunmalı — sadece kod organizasyonu ve compact TopNav
- Hardcoded renk/spacing yasak
- Tablet test'te regression yok

---

### 🧪 @qa-engineer — Test

**1) Regression:**
```bash
cd packages/drawing_ui && flutter test
```

**2) Yeni testler: top_navigation_bar compact mode**

```dart
testWidgets('TopNavigationBar compact mode shows minimal buttons', (tester) async {
  // compact: true ile pump et
  // Home ve more butonları var
  // Camera, crop, mic butonları yok
});

testWidgets('TopNavigationBar default mode shows all buttons', (tester) async {
  // compact: false (default) ile pump et
  // Tüm butonlar var — regression yok
});
```

---

### 🔍 @code-reviewer — Review

**Kontrol listesi:**
1. drawing_screen.dart ≤ 300 satır
2. drawing_screen_layout.dart ≤ 300 satır
3. top_navigation_bar.dart compact mode düzgün
4. Phone'da compact TopNav gösteriliyor
5. Tablet'te full TopNav korunuyor
6. Canvas area ve sidebar ayrı dosyadan çağrılıyor
7. Barrel exports güncel
8. Hardcoded renk/spacing yok
9. flutter analyze: 0 error
10. Tüm testler pass

---

## COMMIT
```
feat(ui): split DrawingScreen layout helpers + add compact TopNav

- Extract canvas/sidebar builders to drawing_screen_layout.dart
- Add compact mode to TopNavigationBar (minimal phone layout)
- DrawingScreen reduced from 729 to <300 lines
- Update barrel exports
- No regression
```

## SONRAKİ ADIM
Adım 5: Test suite + tablet/phone manual test + final polish + commit message
