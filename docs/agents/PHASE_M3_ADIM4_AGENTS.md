# PHASE M3 — ADIM 4/6: Okuyucu Modu (Read-Only Mode)

## ÖZET
TopNavigationBar'daki "Okuyucu Modu" butonunu aktif et. Toolbar gizlenir, canvas tam ekran, çizim devre dışı, "Salt okunur" badge gösterilir. GoodNotes referansı: goodnotes_04_readonly_mode.jpeg.

## BRANCH
```bash
git checkout feature/toolbar-professional
```

---

## MİMARİ KARAR

Okuyucu modu bir UI state değişikliği — kalıcı veri değişikliği yok, sadece görüntüleme modu. Provider ile yönetilir, SharedPreferences'a kaydetmeye gerek yok (her açılışta normal modda başlar).

Aktif olduğunda:
- Row 2 (ToolBar/AdaptiveToolbar) → AnimatedSize ile height 0'a küçülür
- Row 1 (TopNavigationBar) → Minimal mod: Home + Başlık + "Salt okunur" badge + Export + More
- Canvas → Tam ekran, çizim gesture'ları devre dışı
- Sidebar → Açılabilir (sayfa gezintisi hâlâ aktif)
- Sayfa geçişi → Swipe ile aktif

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- docs/agents/goodnotes_04_readonly_mode.jpeg — GoodNotes salt okunur modu
- packages/drawing_ui/lib/src/toolbar/top_navigation_bar.dart — okuyucu modu butonu (şu an disabled)
- packages/drawing_ui/lib/src/screens/drawing_screen.dart — ana ekran layout
- packages/drawing_ui/lib/src/canvas/drawing_canvas.dart — gesture handler'lar

**1) YENİ DOSYA: `packages/drawing_ui/lib/src/providers/reader_mode_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reader mode state — when active, toolbar is hidden and drawing is disabled.
/// Resets to false on each app launch (not persisted).
final readerModeProvider = StateProvider<bool>((ref) => false);
```

Basit, tek satır provider. Persist etmeye gerek yok.

**2) GÜNCELLE: `providers.dart` barrel**

```dart
export 'reader_mode_provider.dart';
```

**3) GÜNCELLE: `top_navigation_bar.dart` — Okuyucu modu toggle**

Okuyucu modu butonunu aktif et (isDisabled: false) ve toggle logic ekle:

```dart
// Sağ bölgede:
StarNoteNavButton(
  icon: isReaderMode
      ? ElyanotesIcons.readerModeActive  // Bold/filled ikon
      : ElyanotesIcons.readerMode,
  tooltip: isReaderMode ? 'Düzenleme Modu' : 'Okuyucu Modu',
  onPressed: () {
    ref.read(readerModeProvider.notifier).state = !isReaderMode;
  },
  isActive: isReaderMode,
),
```

Okuyucu modu aktifken TopNavigationBar'da "Salt okunur" badge göster:

```dart
// Başlık yanında veya ortada:
if (isReaderMode)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(
          ElyanotesIcons.readerMode,
          size: 14,
          color: colorScheme.onSecondaryContainer,
        ),
        const SizedBox(width: 4),
        Text(
          'Salt okunur',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    ),
  ),
```

Okuyucu modunda sağ bölgeden bazı butonları gizle (Grid toggle gereksiz, Okuyucu modu toggle kalır):

```dart
// Reader mode'da:
// Göster: Home, Sidebar, Başlık, "Salt okunur" badge, Okuyucu toggle, Export, More
// Gizle: Grid toggle (çizim yok, grid gereksiz)
if (!isReaderMode)
  StarNoteNavButton(
    icon: gridVisible ? ElyanotesIcons.gridOn : ElyanotesIcons.gridOff,
    ...
  ),
```

**4) GÜNCELLE: `drawing_screen.dart` — Toolbar gizleme + çizim devre dışı**

```dart
@override
Widget build(BuildContext context) {
  final isReaderMode = ref.watch(readerModeProvider);
  // ... mevcut kod ...

  return Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // Row 1: TopNav (her zaman göster)
              TopNavigationBar(
                // ... mevcut parametreler ...
              ),

              // Row 2: Toolbar — okuyucu modunda animasyonlu gizleme
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: isReaderMode
                    ? const SizedBox.shrink()
                    : AdaptiveToolbar(
                        // ... mevcut parametreler ...
                      ),
              ),

              // Row 3: Canvas
              Expanded(
                child: Row(
                  children: [
                    // Sidebar (tablet — okuyucu modunda da açılabilir)
                    // ...

                    // Canvas
                    Expanded(
                      child: _buildCanvasArea(
                        context,
                        currentPage,
                        transform,
                        isReadOnly: isReaderMode, // YENİ parametre
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Panel overlay (okuyucu modunda gösterme)
          if (!isReaderMode && !isCompactMode) ...[
            // mevcut AnchoredPanel overlay kodu
          ],
        ],
      ),
    ),
    // Phone bottom bar (okuyucu modunda gösterme)
    bottomNavigationBar: isCompactMode && !isReaderMode
        ? CompactBottomBar(...)
        : null,
  );
}
```

**5) GÜNCELLE: Canvas — çizim devre dışı**

Canvas widget'ına `isReadOnly` parametresi ekle. True olduğunda:
- Pan/zoom gesture'ları AKTİF (sayfa gezintisi çalışsın)
- Çizim gesture'ları DEVRE DIŞI (onPanStart/Update/End ignore)
- Cursor hint gösterme

Bu DrawingCanvas veya gesture handler seviyesinde yapılabilir. En temiz yaklaşım:

```dart
// drawing_canvas.dart veya gesture handler'da:
if (isReadOnly) {
  // Sadece pan/zoom gesture'larını işle
  // Çizim, eraser, selection gesture'larını ignore et
  return;
}
```

Alternatif: `drawing_screen_layout.dart`'taki `buildDrawingCanvasArea` fonksiyonuna `isReadOnly` parametresi ekle. Bu fonksiyon canvas'ı oluştururken `AbsorbPointer` veya `IgnorePointer` ile çizim gesture'larını engeller ama pan/zoom'u InteractiveViewer üzerinden korur.

**EN BASİT YAKLAŞIM:**
DrawingCanvas'ın gesture callback'lerini null geç:

```dart
DrawingCanvas(
  // ... mevcut parametreler ...
  onDrawStart: isReadOnly ? null : _onDrawStart,
  onDrawUpdate: isReadOnly ? null : _onDrawUpdate,
  onDrawEnd: isReadOnly ? null : _onDrawEnd,
  // Pan/zoom her zaman aktif
)
```

Eğer DrawingCanvas bu callback'ler null olduğunda çizim yapmıyorsa, bu yeterli.

**6) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**MANUEL TEST:**
1. TopNav'daki okuyucu modu butonuna bas → Toolbar kaybolur, "Salt okunur" badge görünür
2. Canvas'ta çizim dene → Çizim yapılamamalı
3. Sayfa swipe et → Sayfa geçişi çalışmalı
4. Sidebar aç → Sayfa thumbnail'larına tıkla, çalışmalı
5. Tekrar okuyucu modu butonuna bas → Toolbar geri gelir, çizim aktif
6. Dark mode'da test et → Badge ve butonlar doğru renkte

**KURALLAR:**
- AnimatedSize ile smooth geçiş (200ms)
- Okuyucu modunda pan/zoom AKTİF, çizim DEVRE DIŞI
- Badge: secondaryContainer renk, küçük ve sade
- reader_mode_provider.dart max 10 satır
- drawing_screen.dart 300 satır limitine dikkat — aşarsa layout helper'a taşı

---

### 🧪 @qa-engineer — Test

```dart
void main() {
  group('Reader Mode', () {
    test('default is false', () {
      final container = ProviderContainer();
      expect(container.read(readerModeProvider), false);
      container.dispose();
    });

    test('toggle changes state', () {
      final container = ProviderContainer();
      container.read(readerModeProvider.notifier).state = true;
      expect(container.read(readerModeProvider), true);
      container.dispose();
    });

    testWidgets('toolbar hidden when reader mode active', (tester) async {
      // DrawingScreen pump et
      // readerModeProvider true yap
      // AdaptiveToolbar/ToolBar bulunmamalı
    });

    testWidgets('salt okunur badge visible in reader mode', (tester) async {
      // readerModeProvider true
      // "Salt okunur" text bulunmalı
    });
  });
}
```

---

## COMMIT
```
feat(ui): add Reader Mode — hide toolbar, show read-only badge

- Add readerModeProvider (simple bool toggle)
- TopNavigationBar: reader mode toggle active, "Salt okunur" badge
- DrawingScreen: AnimatedSize toolbar hide, disable drawing gestures
- Pan/zoom still active in reader mode
- Sidebar accessible in reader mode
```

## SONRAKİ ADIM
Adım 5: Page Navigator + Sayfa Göstergesi
