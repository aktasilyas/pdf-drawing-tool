# 🔧 GÖREV: Zoom Baseline Fix + Dual Page Kaldırma + Zoom Lock

## 📋 ÖZET
3 iş yapılacak:
1. **Dual page mode'u devre dışı bırak** (geçici, UI'dan gizle)
2. **Zoom baseline sorununu düzelt** (100% = sayfa viewport'a tam oturmalı)
3. **Zoom lock/favori özelliği ekle** (kullanıcı istediği zoom oranını kilitleyebilmeli)

**Branch:** `fix/zoom-baseline-and-lock`

---

## ⚠️ KURALLAR
- Her adımdan sonra `flutter analyze` çalıştır, sıfır hata olmalı
- Mevcut testleri kırma, her adımda `flutter test` çalıştır
- Değişiklik yapacağın dosyayı önce tamamen oku
- Küçük, incremental commit'ler at

---

## ADIM 1: Dual Page Mode'u Geçici Olarak Devre Dışı Bırak

### Amaç
Dual page özelliği şimdilik kullanılmayacak. UI'dan gizle ama kodu silme.

### Yapılacaklar

**Dosya:** `packages/drawing_ui/lib/src/panels/page_options_panel.dart`
- `_DualPageModeItem` widget'ını page options panel'den kaldır (widget'ı silme, sadece kullanıldığı yerdeki referansı comment out et)

**Dosya:** `packages/drawing_ui/lib/src/screens/drawing_screen_layout.dart`
- Dual page Row layout'unu devre dışı bırak. `isDualPage` kontrolünü her zaman `false` yap veya comment out et:
```dart
// TEMPORARILY DISABLED: Dual page mode
// if (isDualPage) { ... }
```

**Dosya:** `packages/drawing_ui/lib/src/screens/drawing_screen.dart`
- Dual page ile ilgili viewport hesaplamalarını (`canvasWidth /= 2`) comment out et

**Test:** Uygulamayı aç, page options panel'de "Çift sayfa görünümü" toggle'ının görünmediğini doğrula.

**Commit:** `chore: temporarily disable dual page mode`

---

## ADIM 2: Baseline Zoom Kavramını Implement Et

### Sorun
Şu an `zoom = 1.0` sayfanın native piksel boyutunu temsil ediyor. Ama notebook/PDF modunda kullanıcı 100%'den "sayfa ekrana tam oturmuş" halini bekliyor. Örnek:
- A4 sayfa: 595x842px
- Viewport: ~768x758px (toolbar çıkınca)
- `fitHeightZoom = 758 / 842 ≈ 0.90`
- Sayfa ekrana oturuyor ama UI "90%" gösteriyor → yanlış

### Çözüm Mimarisi
`baselineZoom` kavramı ekle. Bu değer "sayfa viewport'a tam oturduğundaki zoom seviyesi". UI'da gösterilen yüzde = `(currentZoom / baselineZoom * 100).round()%`. Yani baselineZoom'da UI "100%" gösterir.

### Yapılacaklar

**Dosya:** `packages/drawing_ui/lib/src/providers/canvas_transform_provider.dart`

#### 2a. CanvasTransform'a baselineZoom ekle
```dart
class CanvasTransform {
  final double zoom;
  final Offset offset;
  
  /// Baseline zoom = sayfa viewport'a tam oturduğundaki zoom seviyesi.
  /// UI'da "100%" bu değere karşılık gelir.
  /// Whiteboard/infinite mode için 1.0.
  final double baselineZoom;

  const CanvasTransform({
    this.zoom = 1.0,
    this.offset = Offset.zero,
    this.baselineZoom = 1.0,
  });

  /// UI'da gösterilecek yüzde değeri.
  /// baselineZoom'da 100%, baselineZoom*2'de 200% gösterir.
  double get displayPercentage => (zoom / baselineZoom) * 100;

  // copyWith'e baselineZoom ekle
  CanvasTransform copyWith({double? zoom, Offset? offset, double? baselineZoom}) {
    return CanvasTransform(
      zoom: zoom ?? this.zoom,
      offset: offset ?? this.offset,
      baselineZoom: baselineZoom ?? this.baselineZoom,
    );
  }

  // equality ve hashCode'a baselineZoom ekle
}
```

#### 2b. initializeForPage'i güncelle
```dart
void initializeForPage({
  required Size viewportSize,
  required Size pageSize,
}) {
  // Fit-to-height zoom hesapla
  final fitHeightZoom = viewportSize.height / pageSize.height;
  
  // Center page both horizontally AND vertically
  final pageScreenWidth = pageSize.width * fitHeightZoom;
  final pageScreenHeight = pageSize.height * fitHeightZoom;
  final offsetX = (viewportSize.width - pageScreenWidth) / 2;
  final offsetY = (viewportSize.height - pageScreenHeight) / 2;

  state = CanvasTransform(
    zoom: fitHeightZoom,
    offset: Offset(offsetX, offsetY),
    baselineZoom: fitHeightZoom, // ← Bu kritik!
  );
}
```

#### 2c. snapBackForPage'i güncelle
`snapBackForPage` içinde de `baselineZoom`'u koru:
```dart
void snapBackForPage({
  required Size viewportSize,
  required Size pageSize,
}) {
  final baselineZoom = viewportSize.height / pageSize.height;
  
  if (state.zoom < baselineZoom) {
    final pageScreenWidth = pageSize.width * baselineZoom;
    final offsetX = (viewportSize.width - pageScreenWidth) / 2;
    final offsetY = (viewportSize.height - pageSize.height * baselineZoom) / 2;

    state = CanvasTransform(
      zoom: baselineZoom,
      offset: Offset(offsetX, offsetY),
      baselineZoom: baselineZoom,
    );
  } else {
    _clampOffsetLimitedCanvas(viewportSize, pageSize);
  }
}
```

#### 2d. Zoom percentage provider'ı güncelle
```dart
/// Zoom percentage string for UI display.
/// Artık baselineZoom'a göre hesaplanıyor: baseline = 100%.
final zoomPercentageProvider = Provider<String>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  final percentage = transform.displayPercentage.round();
  return '$percentage%';
});

/// Whether canvas is at baseline zoom (what user sees as "100%").
final isDefaultZoomProvider = Provider<bool>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  return (transform.zoom - transform.baselineZoom).abs() < 0.01;
});
```

#### 2e. fitToScreen ve reset metodlarını güncelle
```dart
void fitToScreen() {
  // baselineZoom'a dön, default offset'e dön
  // Bu metod sadece baselineZoom biliniyorsa doğru çalışır
  // viewportSize ve pageSize gerekiyor, bu yüzden parametreli yap
  // VEYA mevcut baselineZoom'u kullan
  state = CanvasTransform(
    zoom: state.baselineZoom, 
    offset: Offset.zero,
    baselineZoom: state.baselineZoom,
  );
}

void reset() {
  state = CanvasTransform(
    zoom: state.baselineZoom,
    offset: Offset.zero,
    baselineZoom: state.baselineZoom,
  );
}
```

**NOT:** `fitToScreen` metodunu çağıran yerlerde viewportSize ve pageSize varsa, `initializeForPage`'i çağırmak daha doğru olabilir. Mevcut çağrı noktalarını kontrol et.

**Dosya:** `packages/drawing_ui/lib/src/canvas/drawing_canvas.dart`

#### 2f. effectiveTransform fallback'ini düzelt
`DrawingCanvas.build()` içindeki `effectiveTransform` hesabını güncelle:
```dart
// CRITICAL FIX: Use computed transform if still at default state
CanvasTransform effectiveTransform = transform;
if (!canvasMode.isInfinite) {
  final isDefaultTransform = 
      transform.zoom == 1.0 && transform.offset == Offset.zero;
  if (isDefaultTransform) {
    // Compute fit-to-height transform for first frame
    final pageSize = Size(currentPage.size.width, currentPage.size.height);
    final fitHeightZoom = size.height / pageSize.height;
    
    final pageScreenWidth = pageSize.width * fitHeightZoom;
    final pageScreenHeight = pageSize.height * fitHeightZoom;
    final offsetX = (size.width - pageScreenWidth) / 2;
    final offsetY = (size.height - pageScreenHeight) / 2;
    
    effectiveTransform = CanvasTransform(
      zoom: fitHeightZoom,
      offset: Offset(offsetX, offsetY),
      baselineZoom: fitHeightZoom,
    );
  }
}
```

#### 2g. _clampOffsetLimitedCanvas'ı düzelt — center vertical
Sayfayı top-align yerine center et (sayfa viewport'tan küçükken):
```dart
// Vertical clamping
if (pageScreenHeight <= viewportSize.height) {
  // Page shorter than viewport: CENTER vertically (not top-align!)
  newOffset = Offset(
    newOffset.dx,
    (viewportSize.height - pageScreenHeight) / 2, // ← Değişiklik burada
  );
} else {
  // Page taller than viewport: clamp to keep within bounds
  final minY = viewportSize.height - pageScreenHeight;
  final maxY = 0.0;
  newOffset = Offset(
    newOffset.dx,
    newOffset.dy.clamp(minY, maxY),
  );
}
```

**NOT:** Bu değişikliğin zoom-in durumunda etkisi olmayacak (sayfa viewport'tan büyükken else branch çalışıyor). Sadece fit-to-height veya zoom-out durumunda sayfa dikeyde ortalanacak.

**Test:** 
- Notebook aç → sayfa hem yatay hem dikey ortalanmış olmalı
- Zoom indicator "100%" göstermeli
- Pinch zoom yap → yüzde doğru artmalı/azalmalı
- PDF aç → aynı davranış

**Commit:** `fix: implement baseline zoom - 100% now means fit-to-viewport`

---

## ADIM 3: Mevcut Testleri Güncelle

**Dosya:** `packages/drawing_ui/test/providers/canvas_transform_provider_test.dart`

Mevcut testler `CanvasTransform` constructor'ını kullanıyor. `baselineZoom` parametresi eklendiği için güncellenmeli:

- `equality` testine baselineZoom ekle
- `copyWith` testine baselineZoom ekle  
- `displayPercentage` için yeni test ekle:
```dart
test('displayPercentage is relative to baselineZoom', () {
  const t = CanvasTransform(zoom: 0.9, baselineZoom: 0.9);
  expect(t.displayPercentage, closeTo(100.0, 0.1));
  
  const t2 = CanvasTransform(zoom: 1.8, baselineZoom: 0.9);
  expect(t2.displayPercentage, closeTo(200.0, 0.1));
});

test('displayPercentage defaults to raw zoom when baselineZoom is 1.0', () {
  const t = CanvasTransform(zoom: 1.5, baselineZoom: 1.0);
  expect(t.displayPercentage, closeTo(150.0, 0.1));
});
```

- `initializeForPage` testini güncelle: baselineZoom'un doğru set edildiğini kontrol et
- `snapBackForPage` testini güncelle: baselineZoom'un korunduğunu kontrol et

**Commit:** `test: update canvas transform tests for baseline zoom`

---

## ADIM 4: Zoom Lock / Favori Özelliği

### Amaç
Kullanıcı istediği bir zoom seviyesinde "kilitle" diyebilmeli. Kilitli iken zoom gesture'ları çalışmasın. Ayrıca favori zoom oranlarını kaydedebilmeli.

### Yapılacaklar

**Dosya:** `packages/drawing_ui/lib/src/providers/zoom_lock_provider.dart` (YENİ)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zoom kilitli mi?
final zoomLockedProvider = StateProvider<bool>((ref) => false);

/// Favori zoom oranları (baselineZoom'a göre yüzde olarak).
/// Varsayılan: [100, 150, 200]
final favoriteZoomsProvider = 
    StateNotifierProvider<FavoriteZoomsNotifier, List<int>>(
  (ref) => FavoriteZoomsNotifier(),
);

class FavoriteZoomsNotifier extends StateNotifier<List<int>> {
  FavoriteZoomsNotifier() : super([100, 150, 200]) {
    _load();
  }

  static const _key = 'favorite_zooms';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved != null && saved.isNotEmpty) {
      state = saved.map((s) => int.tryParse(s) ?? 100).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((z) => z.toString()).toList());
  }

  void addFavorite(int zoomPercent) {
    if (!state.contains(zoomPercent)) {
      state = [...state, zoomPercent]..sort();
      _save();
    }
  }

  void removeFavorite(int zoomPercent) {
    state = state.where((z) => z != zoomPercent).toList();
    _save();
  }

  void toggleFavorite(int zoomPercent) {
    if (state.contains(zoomPercent)) {
      removeFavorite(zoomPercent);
    } else {
      addFavorite(zoomPercent);
    }
  }
}
```

**Dosya:** `packages/drawing_ui/lib/src/canvas/drawing_canvas_gesture_handlers.dart`

`handleScaleUpdate` içinde zoom kilit kontrolü ekle:
```dart
void handleScaleUpdate(ScaleUpdateDetails details) {
  // ... mevcut kod ...
  
  // Zoom gesture'ı (pinch)
  if (lastScale != null && details.scale != 1.0) {
    // ZOOM LOCK CHECK
    final isZoomLocked = ref.read(zoomLockedProvider);
    if (isZoomLocked) {
      // Zoom kilitli, sadece pan'a izin ver (aşağıdaki pan kodu çalışacak)
      // Zoom değişikliğini atla
    } else {
      final scaleDelta = details.scale / lastScale!;
      // ... mevcut zoom kodu ...
    }
  }
  
  // ... pan kodu (bu her zaman çalışmalı, kilitli olsa bile) ...
}
```

**Dosya:** `packages/drawing_ui/lib/src/widgets/zoom_indicator.dart` (MEVCUT veya YENİ)

Zoom indicator widget'ına şu özellikler ekle:
- Mevcut zoom yüzdesini göster (baselineZoom'a göre)
- Kilit ikonu (🔒/🔓) — tıklayınca toggle
- Favori yıldız ikonu (⭐) — tıklayınca mevcut zoom'u favorilere ekle/çıkar
- Favori zoom listesi — tıklayınca o zoom'a git

Zoom indicator'ın UI yapısı (compact, toolbar'a uyumlu):
```
┌──────────────────────────────────┐
│  🔒  125%  ⭐  │  [100%] [150%] [200%]  │
└──────────────────────────────────┘
```

Favori zoom'a tıklandığında:
```dart
void _goToZoom(int targetPercent) {
  final transform = ref.read(canvasTransformProvider);
  final targetZoom = transform.baselineZoom * targetPercent / 100;
  
  // Viewport ve page size gerekiyor, bunları context'ten veya provider'dan al
  ref.read(canvasTransformProvider.notifier).setZoom(
    targetZoom,
    minZoom: canvasMode.minZoom,
    maxZoom: canvasMode.maxZoom,
  );
  
  // Offset'i recenter et
  // ... viewportSize ve pageSize ile _clampOffsetLimitedCanvas çağır
}
```

**NOT:** `setZoom` metodu mevcut. Ama sonrasında offset'in de doğru hesaplanması lazım. `CanvasTransformNotifier`'a yeni bir metod ekle:

```dart
/// Belirli bir zoom seviyesine git ve sayfayı ortala.
void goToZoom({
  required double targetZoom,
  required Size viewportSize,
  required Size pageSize,
  double minZoom = 0.25,
  double maxZoom = 5.0,
}) {
  final clampedZoom = targetZoom.clamp(minZoom, maxZoom);
  
  final pageScreenWidth = pageSize.width * clampedZoom;
  final pageScreenHeight = pageSize.height * clampedZoom;
  
  // Center page
  final offsetX = pageScreenWidth <= viewportSize.width 
      ? (viewportSize.width - pageScreenWidth) / 2 
      : 0.0;
  final offsetY = pageScreenHeight <= viewportSize.height 
      ? (viewportSize.height - pageScreenHeight) / 2 
      : 0.0;
  
  state = state.copyWith(
    zoom: clampedZoom,
    offset: Offset(offsetX, offsetY),
  );
}
```

**Dosya:** `packages/drawing_ui/lib/src/providers/providers.dart` (barrel export)
- `zoom_lock_provider.dart`'ı export et

**Test:**
- Zoom lock aktifken pinch zoom çalışmamalı, pan çalışmalı
- Favori ekle/çıkar → SharedPreferences'a kaydedilmeli
- Favori zoom'a tıklayınca doğru zoom seviyesine gitmeli
- Uygulama yeniden açıldığında favoriler korunmalı

**Commit:** `feat: add zoom lock and favorite zoom levels`

---

## ADIM 5: Landscape / Portrait Geçişinde Test

Cihaz döndürüldüğünde:
- `initializeForPage` yeni viewport ile tekrar çağrılmalı
- `baselineZoom` yeni viewport'a göre güncellenmeli
- Sayfa yine viewport'a fit olmalı ve "100%" göstermeli

Mevcut `recenterForViewport` sadece offset clamp yapıyor, baselineZoom'u güncellemesi lazım.

**Dosya:** `packages/drawing_ui/lib/src/providers/canvas_transform_provider.dart`

```dart
void recenterForViewport({
  required Size viewportSize,
  required Size pageSize,
}) {
  // Yeni baselineZoom hesapla
  final newBaselineZoom = viewportSize.height / pageSize.height;
  
  // Mevcut göreli zoom'u koru
  // Örn: kullanıcı 150%'deydi → rotate sonrası da 150%'de kalmalı
  final currentRelativeZoom = state.baselineZoom > 0 
      ? state.zoom / state.baselineZoom 
      : 1.0;
  final newZoom = newBaselineZoom * currentRelativeZoom;
  
  state = state.copyWith(
    zoom: newZoom,
    baselineZoom: newBaselineZoom,
  );
  
  // Offset'i yeni viewport'a göre clamp et
  _clampOffsetLimitedCanvas(viewportSize, pageSize);
}
```

**Test:** Tablet'i portrait → landscape → portrait döndür. Her seferinde sayfa ortalı ve zoom yüzdesi korunmalı.

**Commit:** `fix: preserve relative zoom on viewport change (rotation)`

---

## ADIM 6: Final Test Checklist

- [ ] Notebook aç → sayfa ortalı, "100%" gösteriyor
- [ ] PDF aç → sayfa ortalı, "100%" gösteriyor  
- [ ] Pinch zoom in → yüzde artıyor (150%, 200%...)
- [ ] Pinch zoom out → minimum "100%"'e snap back
- [ ] Zoom lock toggle → kilitli iken zoom çalışmıyor, pan çalışıyor
- [ ] Favori zoom ekle → listeye ekleniyor
- [ ] Favori zoom'a tıkla → o zoom'a gidiyor ve sayfa ortalanıyor
- [ ] Tablet döndür → sayfa yeniden ortalanıyor, göreli zoom korunuyor
- [ ] Dual page toggle UI'da görünmüyor
- [ ] Whiteboard modu → baselineZoom = 1.0, eski davranış korunuyor
- [ ] Mevcut tüm testler geçiyor
- [ ] `flutter analyze` sıfır hata

**Final commit:** `chore: zoom baseline fix complete - merge ready`
