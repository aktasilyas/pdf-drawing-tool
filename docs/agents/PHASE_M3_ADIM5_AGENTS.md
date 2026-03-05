# PHASE M3 — ADIM 5/6: Page Indicator Bar + Swipe Navigasyonu

## ÖZET
Canvas altına kompakt sayfa göstergesi (← Sayfa 1/5 →) ve swipe ile sayfa geçişi. GoodNotes'taki teal bar referansı.

## BRANCH
```bash
git checkout feature/toolbar-professional
```

---

## MİMARİ KARAR

Mevcut altyapı hazır — kullanılacak provider'lar:
- `currentPageIndexProvider` — mevcut sayfa index'i
- `pageCountProvider` — toplam sayfa sayısı
- `canGoNextProvider` / `canGoPreviousProvider` — navigasyon durumu
- `pageManagerProvider.notifier` — nextPage() / previousPage() metotları

PageNavigator widget'ı (thumbnail sidebar) zaten var. Bu adımda eklenen: canvas altında minimal gösterge bar'ı + sayfa arası swipe.

Swipe navigasyonu: PageView kullanmıyoruz (her sayfa farklı canvas state'e sahip, ağır). Bunun yerine horizontal drag gesture ile sayfa geçişi yapıyoruz — threshold aşılınca nextPage/previousPage çağrılır.

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/providers/page_provider.dart — tüm page provider'lar (currentPageIndexProvider, pageCountProvider, canGoNextProvider, canGoPreviousProvider, pageManagerProvider)
- packages/drawing_ui/lib/src/screens/drawing_screen.dart — canvas layout
- packages/drawing_ui/lib/src/screens/drawing_screen_layout.dart — buildDrawingCanvasArea
- packages/drawing_ui/lib/src/widgets/page_navigator.dart — mevcut PageNavigator (referans)
- packages/drawing_ui/lib/src/theme/elyanotes_icons.dart — ikon tanımları

**1) YENİ DOSYA: `packages/drawing_ui/lib/src/widgets/page_indicator_bar.dart`**

Canvas altında kompakt sayfa göstergesi. Max 150 satır.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Compact page indicator bar shown below the canvas.
///
/// Shows current page number, total pages, and navigation arrows.
/// Only visible when document has more than one page.
/// Fades out after 3 seconds of inactivity, reappears on interaction.
class PageIndicatorBar extends ConsumerStatefulWidget {
  const PageIndicatorBar({
    super.key,
    this.autoHide = true,
    this.autoHideDuration = const Duration(seconds: 3),
  });

  /// Whether to auto-hide after inactivity.
  final bool autoHide;

  /// Duration before auto-hiding.
  final Duration autoHideDuration;

  @override
  ConsumerState<PageIndicatorBar> createState() => _PageIndicatorBarState();
}

class _PageIndicatorBarState extends ConsumerState<PageIndicatorBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Başlangıçta görünür
    );
    if (widget.autoHide) {
      _startAutoHideTimer();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startAutoHideTimer() {
    Future.delayed(widget.autoHideDuration, () {
      if (mounted && widget.autoHide && _isVisible) {
        _fadeController.reverse();
        _isVisible = false;
      }
    });
  }

  void _showIndicator() {
    if (!_isVisible) {
      _fadeController.forward();
      _isVisible = true;
    }
    if (widget.autoHide) {
      _startAutoHideTimer();
    }
  }

  @override
  void didUpdateWidget(covariant PageIndicatorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sayfa değiştiğinde göster
    _showIndicator();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = ref.watch(pageCountProvider);
    final currentIndex = ref.watch(currentPageIndexProvider);
    final canGoNext = ref.watch(canGoNextProvider);
    final canGoPrevious = ref.watch(canGoPreviousProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Tek sayfalı dokümanda gösterme
    if (pageCount <= 1) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showIndicator,
      child: FadeTransition(
        opacity: _fadeController,
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 8),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sol ok — önceki sayfa
                  _PageNavButton(
                    icon: ElyanotesIcons.chevronLeft,
                    onPressed: canGoPrevious
                        ? () {
                            ref.read(pageManagerProvider.notifier).previousPage();
                            _showIndicator();
                          }
                        : null,
                  ),

                  // Sayfa numarası
                  GestureDetector(
                    onTap: () => _showGoToPageDialog(context, ref, pageCount),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Sayfa ${currentIndex + 1} / $pageCount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),

                  // Sağ ok — sonraki sayfa
                  _PageNavButton(
                    icon: ElyanotesIcons.chevronRight,
                    onPressed: canGoNext
                        ? () {
                            ref.read(pageManagerProvider.notifier).nextPage();
                            _showIndicator();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGoToPageDialog(BuildContext context, WidgetRef ref, int pageCount) {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sayfaya Git'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - $pageCount',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null && page >= 1 && page <= pageCount) {
              ref.read(pageManagerProvider.notifier).goToPage(page - 1);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= pageCount) {
                ref.read(pageManagerProvider.notifier).goToPage(page - 1);
                Navigator.pop(context);
              }
            },
            child: const Text('Git'),
          ),
        ],
      ),
    );
  }
}

/// Small circular navigation button for page indicator.
class _PageNavButton extends StatelessWidget {
  const _PageNavButton({
    required this.icon,
    required this.onPressed,
  });

  final PhosphorIconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: PhosphorIcon(
              icon,
              size: 16,
              color: isEnabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}
```

**2) GÜNCELLE: `drawing_screen_layout.dart` — PageIndicatorBar yerleştir**

Canvas alanının altına, Stack içinde veya Column sonuna PageIndicatorBar ekle:

```dart
Widget buildDrawingCanvasArea({
  // ... mevcut parametreler ...
}) {
  return Stack(
    children: [
      // Canvas (mevcut — tam ekran)
      Positioned.fill(
        child: // ... mevcut canvas widget ...
      ),

      // Page Indicator — canvas altında, ortada
      const Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: PageIndicatorBar(),
      ),
    ],
  );
}
```

Eğer mevcut yapı Stack değilse, Column + Expanded kullan:
```dart
Column(
  children: [
    Expanded(child: canvasWidget),
    const PageIndicatorBar(),
  ],
)
```

**EN İYİ YAKLAŞIM:** Stack kullan — indicator canvas üzerine float eder, alan kaybetmez.

**3) YENİ: Swipe ile sayfa geçişi**

Canvas alanına horizontal swipe gesture ekle. Bu okuyucu modunda özellikle önemli. Normal modda da çalışsın ama aktif araç panZoom olduğunda veya iki parmak swipe ile.

**EN BASİT YAKLAŞIM — Okuyucu modunda swipe:**

```dart
// drawing_screen_layout.dart veya drawing_screen.dart'ta:
// Canvas'ı GestureDetector ile sar (sadece okuyucu modunda)

if (isReadOnly) {
  // Okuyucu modunda horizontal swipe ile sayfa geçişi
  return GestureDetector(
    onHorizontalDragEnd: (details) {
      final velocity = details.primaryVelocity ?? 0;
      if (velocity < -300) {
        // Sola swipe → sonraki sayfa
        ref.read(pageManagerProvider.notifier).nextPage();
      } else if (velocity > 300) {
        // Sağa swipe → önceki sayfa
        ref.read(pageManagerProvider.notifier).previousPage();
      }
    },
    child: Stack(
      children: [
        canvasWidget,
        const Positioned(
          left: 0, right: 0, bottom: 0,
          child: PageIndicatorBar(),
        ),
      ],
    ),
  );
}
```

**Normal modda (çizim aktif) swipe devre dışı** — çizim gesture'ları ile çakışır. Normal modda sayfa geçişi sadece ok butonları ve sidebar'dan yapılır.

**4) GÜNCELLE: Barrel exports**

```dart
// widgets/widgets.dart barrel:
export 'page_indicator_bar.dart';
```

**5) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**MANUEL TEST:**
1. Çok sayfalı doküman aç → canvas altında "Sayfa 1/5" göstergesi görünmeli
2. Ok butonlarına bas → sayfa değişmeli
3. İlk sayfada sol ok disabled, son sayfada sağ ok disabled
4. "Sayfa 1/5" yazısına tap → "Sayfaya Git" dialog, numara gir, sayfaya atla
5. 3 saniye bekleme → gösterge kaybolur, ekrana dokun → gösterge tekrar çıkar
6. Tek sayfalı doküman → gösterge hiç görünmemeli
7. Okuyucu modunda swipe → sola swipe sonraki sayfa, sağa swipe önceki sayfa
8. Normal modda (çizim aktif) swipe → çizim çalışmalı, sayfa geçişi olmamalı
9. Dark mode'da test → gösterge renkleri doğru

**KURALLAR:**
- PageIndicatorBar max 150 satır
- Tek sayfalı dokümanda gösterme (SizedBox.shrink)
- Auto-hide 3 saniye (opsiyonel)
- "Sayfaya Git" dialog — basit numara girişi
- Swipe SADECE okuyucu modunda (çizim ile çakışmasın)
- Stack ile float — canvas alanı küçülmesin
- Hardcoded renk yasak

---

### 🧪 @qa-engineer — Test

```dart
void main() {
  group('PageIndicatorBar', () {
    test('hidden when single page', ...);
    test('shows page count text', ...);
    test('previous button disabled on first page', ...);
    test('next button disabled on last page', ...);
    test('navigation buttons change page', ...);
  });
}
```

---

## COMMIT
```
feat(ui): add PageIndicatorBar with navigation arrows and swipe

- Compact floating indicator: "Sayfa 1/5" with prev/next arrows
- Tap page number to show "Go to page" dialog
- Auto-hide after 3 seconds, reappear on interaction
- Swipe navigation in reader mode (left=next, right=previous)
- Hidden for single-page documents
```

## SONRAKİ ADIM
Adım 6: Final Polish + Kapsamlı Test + GitHub Push
