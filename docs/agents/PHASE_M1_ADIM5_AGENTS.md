# PHASE M1 — ADIM 5/5: Test Suite + Final Polish

## ÖZET
M1'in tüm adımlarını kapsayan test suite yaz. Responsive geçişleri doğrula. Code review yap. Branch'i merge'e hazırla.

## BRANCH
```bash
git checkout feature/responsive-toolbar
```

---

## AGENT GÖREVLERİ

### 🧪 @qa-engineer — Test Suite

**Ana görev:** M1'de eklenen tüm widget'lar için kapsamlı test yaz.

**1) YENİ: `packages/drawing_ui/test/responsive_toolbar_test.dart`**

Tüm responsive geçişleri tek dosyada test et:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('Responsive Toolbar System', () {

    group('AdaptiveToolbar breakpoints', () {
      testWidgets('≥840px renders ToolBar (expanded)', (tester) async {
        await tester.pumpWidget(_wrapInApp(width: 900));
        // ToolBar widget'ı bulunmalı
        // MediumToolbar bulunmamalı
      });

      testWidgets('600-839px renders MediumToolbar', (tester) async {
        await tester.pumpWidget(_wrapInApp(width: 700));
        // MediumToolbar widget'ı bulunmalı
        // ToolBar (expanded) bulunmamalı
      });

      testWidgets('<600px renders SizedBox.shrink', (tester) async {
        await tester.pumpWidget(_wrapInApp(width: 400));
        // AdaptiveToolbar içinde SizedBox.shrink
        // CompactBottomBar ayrıca render edilmeli (DrawingScreen'de)
      });
    });

    group('MediumToolbar', () {
      testWidgets('shows max 6 tools', (tester) async {
        await tester.pumpWidget(_wrapMediumToolbar());
        // Max 6 ToolButton bulunmalı
      });

      testWidgets('overflow menu contains remaining tools', (tester) async {
        await tester.pumpWidget(_wrapMediumToolbar());
        // Icons.more_horiz bul ve tap et
        // Popup menüde kalan tool isimleri görünmeli
      });

      testWidgets('undo/redo buttons present', (tester) async {
        await tester.pumpWidget(_wrapMediumToolbar());
        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.redo), findsOneWidget);
      });

      testWidgets('tool selection updates provider', (tester) async {
        // Tool'a tap et → currentToolProvider güncellenmiş olmalı
      });
    });

    group('CompactBottomBar', () {
      testWidgets('has 56dp height', (tester) async {
        await tester.pumpWidget(_wrapCompactBottomBar());
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        // height: 56 kontrolü
      });

      testWidgets('shows max 5 tools', (tester) async {
        await tester.pumpWidget(_wrapCompactBottomBar());
        // Max 5 ToolButton bulunmalı
      });

      testWidgets('calls onToolPanelRequested on active tool tap', (tester) async {
        ToolType? requestedTool;
        await tester.pumpWidget(_wrapCompactBottomBar(
          onToolPanelRequested: (tool) => requestedTool = tool,
        ));
        // Aktif tool'a tap et → requestedTool != null
      });

      testWidgets('undo/redo buttons present', (tester) async {
        await tester.pumpWidget(_wrapCompactBottomBar());
        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.redo), findsOneWidget);
      });
    });

    group('ToolbarOverflowMenu', () {
      testWidgets('renders more_horiz icon', (tester) async {
        await tester.pumpWidget(_wrapOverflowMenu());
        expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      });

      testWidgets('popup shows hidden tool names', (tester) async {
        await tester.pumpWidget(_wrapOverflowMenu());
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();
        // Hidden tool displayName'leri görünmeli
      });

      testWidgets('calls onToolSelected', (tester) async {
        ToolType? selected;
        await tester.pumpWidget(_wrapOverflowMenu(
          onToolSelected: (tool) => selected = tool,
        ));
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();
        // İlk tool'a tap et → selected != null
      });
    });

    group('TopNavigationBar compact', () {
      testWidgets('compact=true shows minimal buttons', (tester) async {
        await tester.pumpWidget(_wrapTopNav(compact: true));
        // Home icon var
        // Camera, crop, mic yok veya gizli
      });

      testWidgets('compact=false shows all buttons', (tester) async {
        await tester.pumpWidget(_wrapTopNav(compact: false));
        // Tüm butonlar var
      });
    });

    group('ToolbarLayoutMode', () {
      test('has exactly three values', () {
        expect(ToolbarLayoutMode.values.length, 3);
      });

      test('shouldUseCompactMode returns true for <600', () {
        expect(AdaptiveToolbar.shouldUseCompactMode(400), isTrue);
        expect(AdaptiveToolbar.shouldUseCompactMode(599), isTrue);
      });

      test('shouldUseCompactMode returns false for ≥600', () {
        expect(AdaptiveToolbar.shouldUseCompactMode(600), isFalse);
        expect(AdaptiveToolbar.shouldUseCompactMode(900), isFalse);
      });
    });
  });
}

// Helper fonksiyonlar — her biri ProviderScope + MaterialApp + gerekli override'lar
Widget _wrapInApp({required double width}) { /* ... */ }
Widget _wrapMediumToolbar() { /* ... */ }
Widget _wrapCompactBottomBar({ValueChanged<ToolType>? onToolPanelRequested}) { /* ... */ }
Widget _wrapOverflowMenu({ValueChanged<ToolType>? onToolSelected}) { /* ... */ }
Widget _wrapTopNav({bool compact = false}) { /* ... */ }
```

**2) Mevcut testleri çalıştır:**
```bash
cd packages/drawing_ui && flutter test
```

**3) Coverage raporu:**
```bash
cd packages/drawing_ui && flutter test --coverage
# Yeni dosyaların coverage'ını kontrol et
```

**Hedef:** Minimum 20 yeni test. Tüm yeni widget'lar (MediumToolbar, CompactBottomBar, ToolbarOverflowMenu, TopNav compact) test edilmiş olmalı.

---

### 🔍 @code-reviewer — Final Review

**Tüm M1 dosyalarını review et:**

**Yeni dosyalar (6 adet):**
1. `toolbar_layout_mode.dart` — enum, kısa, temiz olmalı
2. `adaptive_toolbar.dart` — LayoutBuilder, breakpoint'ler doğru mu
3. `medium_toolbar.dart` — max 300 satır, ToolButton reuse
4. `toolbar_overflow_menu.dart` — PopupMenuButton, theme renkleri
5. `compact_bottom_bar.dart` — 56dp, SafeArea, max 5 tool
6. `compact_tool_panel_sheet.dart` — DraggableScrollableSheet, buildActivePanel reuse

**Güncellenen dosyalar (5 adet):**
7. `tool_bar.dart` — _buildExpandedLayout extract
8. `drawing_screen.dart` — ≤300 satır, isCompactMode logic
9. `drawing_screen_layout.dart` — ≤300 satır, canvas/sidebar builders
10. `top_navigation_bar.dart` — compact mode
11. `drawing_ui.dart` + `toolbar.dart` — barrel exports tam

**Kontrol listesi:**
1. Tüm dosyalar ≤300 satır
2. Barrel exports eksiksiz
3. Relative import yok
4. Hardcoded renk yok (DrawingTheme / colorScheme)
5. Hardcoded spacing yok
6. Touch target min 48dp
7. SafeArea kullanımı doğru
8. Provider kullanımı tutarlı (currentToolProvider, activePanelProvider, visibleToolsProvider)
9. Phone'da AnchoredPanel gizli, bottom sheet aktif
10. Tablet'te mevcut davranış korunmuş
11. Theme dark/light mode'da her iki toolbar çalışıyor
12. flutter analyze: 0 error
13. Tüm testler pass (pre-existing fail'lar hariç)

---

### 👨‍💻 @flutter-developer — Polish (varsa)

Code reviewer sorun bulursa düzelt. Ayrıca:

1. tool_bar.dart hâlâ 375 satırsa → _buildExpandedLayout içindeki tool mapping helper'larını toolbar_helpers.dart'a taşı
2. Tüm yeni widget'larda dark mode test et (tema renkleri doğru mu)
3. Warning'leri temizle (mümkünse)

---

## MERGE
Tüm testler geçtikten ve review tamamlandıktan sonra:

```bash
git checkout main
git merge feature/responsive-toolbar
git branch -d feature/responsive-toolbar
```

## FINAL COMMIT (eğer polish varsa)
```
test(ui): add comprehensive responsive toolbar test suite

- Add 20+ tests for MediumToolbar, CompactBottomBar, OverflowMenu
- Add responsive breakpoint tests for AdaptiveToolbar
- Add TopNavigationBar compact mode tests
- Full M1 phase complete: 3-tier responsive toolbar system
```

## M1 PHASE TAMAMLANDI ✅
Sonuç: Elyanotes artık 3 farklı ekran boyutuna adapte olan toolbar sistemine sahip.
- Expanded (≥840px): Full toolbar — tüm araçlar + quick access + actions
- Medium (600-839px): Compact toolbar — 6 araç + overflow menu
- Compact (<600px): Bottom bar — 5 araç + bottom sheet paneller
