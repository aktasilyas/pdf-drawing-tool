# PHASE M2 — ADIM 3/3: Settings UI + platformBrightness + Test

## ÖZET
Settings ekranına "Canvas Teması" seçeneği ekle (Açık/Koyu/Sistem). DrawingScreen'de platformBrightness'ı provider'a bağla. Tüm flow'u test et.

## BRANCH
```bash
git checkout feature/canvas-dark-mode
```

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/providers/canvas_dark_mode_provider.dart — provider'lar
- packages/drawing_ui/lib/src/screens/drawing_screen.dart — platformBrightness entegrasyonu
- example_app/lib/features/settings/presentation/pages/settings_page.dart — mevcut settings sayfası
- example_app/lib/features/settings/presentation/widgets/ — mevcut settings widget'ları

**1) GÜNCELLE: `drawing_screen.dart` — platformBrightness sync**

DrawingScreen build() metodunun başında system brightness'ı provider'a yaz:

```dart
@override
Widget build(BuildContext context) {
  // Sync platform brightness for followSystem mode
  final brightness = MediaQuery.platformBrightnessOf(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ref.read(platformBrightnessProvider.notifier).state = brightness;
    }
  });

  // ... mevcut build kodu ...
}
```

Alternatif (daha temiz): `ref.listen` yerine direkt build içinde set et. Ama addPostFrameCallback daha güvenli çünkü build sırasında provider state değiştirmek uyarı verebilir.

**EN TEMİZ YAKLAŞIM:** Aslında ConsumerStatefulWidget'ın didChangeDependencies() metodu en doğru yer:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final brightness = MediaQuery.platformBrightnessOf(context);
  ref.read(platformBrightnessProvider.notifier).state = brightness;
}
```

Bu her MediaQuery değişikliğinde çağrılır — tam olarak ihtiyacımız olan şey.

**2) YENİ DOSYA: `example_app/lib/features/settings/presentation/widgets/canvas_theme_setting.dart`**

Settings sayfasında canvas teması seçeneği. Mevcut settings widget pattern'ını takip et.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

/// Canvas theme setting tile with segmented button.
class CanvasThemeSetting extends ConsumerWidget {
  const CanvasThemeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(canvasDarkModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 12),
              Text(
                'Canvas Teması',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<CanvasDarkMode>(
              segments: const [
                ButtonSegment(
                  value: CanvasDarkMode.off,
                  label: Text('Açık'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: CanvasDarkMode.on,
                  label: Text('Koyu'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: CanvasDarkMode.followSystem,
                  label: Text('Sistem'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                ref.read(canvasDarkModeProvider.notifier).setMode(selection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**ÖNEMLİ:** `ref.read(canvasDarkModeProvider.notifier)` — eğer notifier StateNotifier ise `.setMode()`, StateProvider ise `.state = value` kullan. Adım 1'de nasıl implement edildiyse ona uy.

**3) GÜNCELLE: Settings sayfası**

`settings_page.dart`'a CanvasThemeSetting widget'ını ekle. Mevcut Görünüm/Appearance section'ına ekle — tema ayarlarının altına.

```dart
// Mevcut tema toggle'ının altına:
CanvasThemeSetting(),
```

**4) GÜNCELLE: DrawingScreen — canvas transition animasyonu (opsiyonel ama güzel)**

Canvas renk geçişi için AnimatedContainer veya TweenAnimationBuilder kullanılabilir. Ama bu performansı etkileyebilir — şimdilik skip, gelecekte eklenebilir.

**5) Doğrulama:**
```bash
flutter analyze && flutter test
cd example_app && flutter run  # tablet'te test et
```

**MANUEL TEST SENARYOLARI:**

1. Settings → Canvas Teması → "Koyu" seç → Drawing screen'e dön → Canvas arka planı koyu gri olmalı, grid çizgileri daha açık gri
2. Settings → Canvas Teması → "Açık" seç → Canvas beyaza dönmeli
3. Settings → Canvas Teması → "Sistem" seç → Tablet dark mode'da koyu, light mode'da açık
4. Custom sayfa rengi olan bir sayfa (kırmızı arka plan gibi) → Dark mode'da kırmızı kalmalı, override edilmemeli
5. PDF sayfası → PDF render'ı etkilenmemeli
6. Uygulama kapat/aç → Seçim korunmuş olmalı (SharedPreferences)

**KURALLAR:**
- Settings widget max 150 satır
- Mevcut settings layout pattern'ını takip et
- SegmentedButton Material 3 widget'ı kullan
- Hardcoded renk yasak
- SharedPreferences persist zaten Adım 1'de yapıldı

---

### 🧪 @qa-engineer — Test

**1) Yeni test: `packages/drawing_ui/test/canvas_dark_mode_test.dart`**

Kapsamlı integration test:

```dart
void main() {
  group('Canvas Dark Mode Full Flow', () {
    test('default mode is off with light scheme', () {
      final container = ProviderContainer();
      expect(container.read(canvasDarkModeProvider), CanvasDarkMode.off);
      expect(
        container.read(canvasColorSchemeProvider).background,
        CanvasColorScheme.light().background,
      );
      container.dispose();
    });

    test('setting mode to on gives dark scheme', () {
      final container = ProviderContainer();
      container.read(canvasDarkModeProvider.notifier).state = CanvasDarkMode.on;
      expect(
        container.read(canvasColorSchemeProvider).background,
        CanvasColorScheme.dark().background,
      );
      container.dispose();
    });

    test('followSystem with dark brightness gives dark scheme', () {
      final container = ProviderContainer(overrides: [
        platformBrightnessProvider.overrideWith((ref) => Brightness.dark),
      ]);
      container.read(canvasDarkModeProvider.notifier).state = CanvasDarkMode.followSystem;
      expect(
        container.read(canvasColorSchemeProvider).background,
        CanvasColorScheme.dark().background,
      );
      container.dispose();
    });

    test('followSystem with light brightness gives light scheme', () {
      final container = ProviderContainer(overrides: [
        platformBrightnessProvider.overrideWith((ref) => Brightness.light),
      ]);
      container.read(canvasDarkModeProvider.notifier).state = CanvasDarkMode.followSystem;
      expect(
        container.read(canvasColorSchemeProvider).background,
        CanvasColorScheme.light().background,
      );
      container.dispose();
    });
  });

  group('CanvasColorScheme effective colors', () {
    test('dark scheme overrides default white background', () {
      final scheme = CanvasColorScheme.dark();
      expect(scheme.effectiveBackground(0xFFFFFFFF), scheme.background);
    });

    test('dark scheme preserves custom page color', () {
      final scheme = CanvasColorScheme.dark();
      expect(scheme.effectiveBackground(0xFFFF0000), const Color(0xFFFF0000));
    });

    test('sepia scheme has warm tones', () {
      final scheme = CanvasColorScheme.sepia();
      expect(scheme.background, const Color(0xFFF5F0E8));
    });
  });

  group('Painter integration', () {
    test('DynamicBackgroundPainter accepts colorScheme', () {
      final painter = DynamicBackgroundPainter(
        background: PageBackground(color: 0xFFFFFFFF, type: BackgroundType.blank),
        colorScheme: CanvasColorScheme.dark(),
      );
      expect(painter.colorScheme, isNotNull);
    });

    test('InfiniteBackgroundPainter accepts colorScheme', () {
      final painter = InfiniteBackgroundPainter(
        background: PageBackground(color: 0xFFFFFFFF, type: BackgroundType.blank),
        colorScheme: CanvasColorScheme.dark(),
      );
      expect(painter.colorScheme, isNotNull);
    });

    test('painters without colorScheme still work', () {
      final painter = DynamicBackgroundPainter(
        background: PageBackground(color: 0xFFFFFFFF, type: BackgroundType.blank),
      );
      expect(painter.colorScheme, isNull);
    });
  });
}
```

---

### 🔍 @code-reviewer — Final M2 Review

**Kontrol listesi:**
1. platformBrightness didChangeDependencies'da sync ediliyor
2. CanvasThemeSetting SegmentedButton kullanıyor
3. Settings'e entegre, mevcut layout korunmuş
4. SharedPreferences persist çalışıyor (uygulama restart'ta korunuyor)
5. Custom sayfa renkleri override edilmiyor
6. PDF render etkilenmemiyor
7. Thumbnail'lar etkilenmemiyor (light scheme)
8. Tüm painter'lar backward compatible
9. Testler kapsamlı
10. flutter analyze clean

---

## MERGE
```bash
git checkout main
git merge feature/canvas-dark-mode
git branch -d feature/canvas-dark-mode
```

## COMMIT
```
feat(canvas): add Canvas Theme setting with dark/light/system modes

- Add CanvasThemeSetting widget (SegmentedButton: Açık/Koyu/Sistem)
- Sync platformBrightness in DrawingScreen.didChangeDependencies
- Settings persistence via SharedPreferences
- Custom page colors preserved, PDF/thumbnails unaffected
- Full M2 phase complete: canvas dark mode system
```

## M2 PHASE TAMAMLANDI ✅
Canvas artık 3 tema modunu destekliyor: Açık (beyaz kağıt), Koyu (koyu gri kağıt), Sistem (otomatik). Rakiplerin %75'inde olmayan bir özellik.
