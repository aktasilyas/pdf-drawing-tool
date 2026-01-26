# 🌙 DARK MODE FIX - CURSOR TALİMATLARI

**Branch:** `fix/dark-mode-panels`
**Tarih:** 26 Ocak 2025
**Öncelik:** 🔴 Yüksek
**Tahmini Süre:** 1-2 gün

---

## 📋 ÖZET

Canvas'taki toolbar panel'leri, page navigator ve modal'larda dark mode çalışmıyor. Hardcoded `Colors.grey`, `Colors.white`, `Colors.black` kullanımları tema renklerine dönüştürülecek.

---

## 🎯 HEDEF

Tüm UI bileşenlerinde tutarlı dark/light mode desteği sağlamak.

---

## 📁 DEĞİŞTİRİLECEK DOSYALAR

### 1. DRAWING_UI PACKAGE (Öncelik: 🔴 Kritik)

#### 1.1 `packages/drawing_ui/lib/src/panels/highlighter_settings_panel.dart`

**Sorunlu Kodlar:**
```dart
// ❌ YANLIŞ
Colors.grey.shade900
Colors.grey.shade50
Colors.grey.shade200
Colors.grey.shade600
```

**Düzeltme:**
```dart
// ✅ DOĞRU
final colorScheme = Theme.of(context).colorScheme;
final isDark = Theme.of(context).brightness == Brightness.dark;

// Colors.grey.shade900 → 
isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest

// Colors.grey.shade50 →
colorScheme.surfaceContainerLowest

// Colors.grey.shade200 →
colorScheme.outlineVariant

// Colors.grey.shade600 →
colorScheme.onSurfaceVariant
```

---

#### 1.2 `packages/drawing_ui/lib/src/panels/eraser_settings_panel.dart`

**Sorunlu Kodlar:**
```dart
// ❌ YANLIŞ
Colors.grey.shade100
Colors.grey.shade300
Colors.grey.shade600
const Color(0xFF4A9DFF) // Hardcoded blue
```

**Düzeltme:**
```dart
// ✅ DOĞRU
final colorScheme = Theme.of(context).colorScheme;

// Colors.grey.shade100 →
colorScheme.surfaceContainerLowest

// Colors.grey.shade300 →
colorScheme.outline

// Colors.grey.shade600 →
colorScheme.onSurfaceVariant

// const Color(0xFF4A9DFF) →
colorScheme.primary
```

---

#### 1.3 `packages/drawing_ui/lib/src/panels/pen_settings_panel.dart`

**Kontrol et ve düzelt:**
- Tüm `Colors.grey` kullanımlarını bul
- `Colors.white` ve `Colors.black` kullanımlarını bul
- Tema renklerine dönüştür

---

#### 1.4 `packages/drawing_ui/lib/src/panels/ai_assistant_panel.dart`

**Sorunlu Kodlar:**
```dart
// ❌ YANLIŞ
Colors.blue
Colors.grey
Colors.grey.shade400
Colors.grey.shade100
Colors.blue.shade700
```

**Düzeltme:**
```dart
// ✅ DOĞRU
final colorScheme = Theme.of(context).colorScheme;

// Colors.blue →
colorScheme.primary

// Colors.grey →
colorScheme.outline

// Colors.grey.shade400 →
colorScheme.onSurfaceVariant

// Colors.grey.shade100 →
colorScheme.surfaceContainerLowest

// Colors.blue.shade700 →
colorScheme.primary
```

---

#### 1.5 `packages/drawing_ui/lib/src/panels/shape_panel.dart`

Kontrol edilecek: Hardcoded renkler varsa düzelt.

---

#### 1.6 `packages/drawing_ui/lib/src/panels/text_style_panel.dart`

Kontrol edilecek: Hardcoded renkler varsa düzelt.

---

#### 1.7 `packages/drawing_ui/lib/src/panels/sticker_panel.dart`

Kontrol edilecek: Hardcoded renkler varsa düzelt.

---

#### 1.8 `packages/drawing_ui/lib/src/widgets/page_navigator.dart`

**Kontrol Noktaları:**
- Bottom sheet background
- ListTile icon ve text renkleri
- Divider renkleri

**Düzeltme Örneği:**
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: colorScheme.surface, // ✅
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.content_copy, color: colorScheme.onSurface), // ✅
          title: Text('Duplicate Page', style: TextStyle(color: colorScheme.onSurface)), // ✅
          onTap: () { ... },
        ),
      ],
    ),
  ),
);
```

---

### 2. EXAMPLE_APP (Öncelik: 🟡 Orta)

#### 2.1 `example_app/lib/features/settings/presentation/widgets/settings_tile.dart`

**Sorunlu Kodlar:**
```dart
// ❌ YANLIŞ
Colors.grey
Colors.grey[600]
Colors.grey[400]
```

**Düzeltme:**
```dart
// ✅ DOĞRU
@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  
  return ListTile(
    leading: Icon(
      icon,
      color: enabled ? colorScheme.onSurface : colorScheme.outline,
    ),
    title: Text(
      title,
      style: TextStyle(
        color: enabled ? colorScheme.onSurface : colorScheme.outline,
      ),
    ),
    subtitle: subtitle != null
        ? Text(
            subtitle!,
            style: TextStyle(
              color: enabled ? colorScheme.onSurfaceVariant : colorScheme.outline,
              fontSize: 13,
            ),
          )
        : null,
    trailing: trailing ?? (showArrow && onTap != null
        ? Icon(Icons.chevron_right, color: colorScheme.outline)
        : null),
    onTap: enabled ? onTap : null,
    enabled: enabled,
  );
}
```

---

#### 2.2 `example_app/lib/features/auth/presentation/widgets/auth_layout.dart`

**Sorunlu Kodlar:**
```dart
// ❌ YANLIŞ
Color(0xFF1A1A1A)
Colors.grey[400]
Colors.grey[50]
Colors.grey[300]
```

**Not:** Auth ekranları genellikle light mode sabit kalabilir. Ancak sistem temasına uyum isteniyorsa düzeltilmeli.

---

#### 2.3 `example_app/lib/features/auth/presentation/screens/login_screen.dart`

**Sorunlu Kodlar:**
```dart
// ❌ YANLIŞ
Colors.grey[300]
Colors.grey[600]
```

---

#### 2.4 `example_app/lib/features/documents/presentation/widgets/document_card.dart`

**Sorunlu Kodlar:**
```dart
// ❌ YANLIŞ
Colors.grey[100]
Colors.grey[200]
```

**Düzeltme:**
```dart
// ✅ DOĞRU
colorScheme.surfaceContainerLowest  // Colors.grey[100]
colorScheme.surfaceContainer        // Colors.grey[200]
```

---

## 🎨 RENK EŞLEŞTİRME TABLOSU

| Hardcoded Renk | Light Mode Karşılığı | ColorScheme Eşdeğeri |
|----------------|---------------------|----------------------|
| `Colors.white` | Beyaz | `colorScheme.surface` |
| `Colors.black` | Siyah | `colorScheme.onSurface` |
| `Colors.grey[50]` | Çok açık gri | `colorScheme.surfaceContainerLowest` |
| `Colors.grey[100]` | Açık gri | `colorScheme.surfaceContainerLowest` |
| `Colors.grey[200]` | Hafif gri | `colorScheme.surfaceContainerLow` |
| `Colors.grey[300]` | Orta açık gri | `colorScheme.outlineVariant` |
| `Colors.grey[400]` | Orta gri | `colorScheme.outline` |
| `Colors.grey[600]` | Koyu gri | `colorScheme.onSurfaceVariant` |
| `Colors.grey[800]` | Çok koyu gri | `colorScheme.onSurface` |
| `Colors.grey[900]` | Neredeyse siyah | `colorScheme.onSurface` |
| `Colors.blue` | Mavi | `colorScheme.primary` |
| `Colors.blue[700]` | Koyu mavi | `colorScheme.primary` |
| `Color(0xFF4A9DFF)` | Özel mavi | `colorScheme.primary` |

---

## 📝 UYGULAMA ADIMLARI

### Adım 1: Branch Oluştur
```bash
git checkout main
git pull
git checkout -b fix/dark-mode-panels
```

### Adım 2: drawing_ui Paketindeki Panel'leri Düzelt

1. `highlighter_settings_panel.dart` - Tüm hardcoded renkleri değiştir
2. `eraser_settings_panel.dart` - Tüm hardcoded renkleri değiştir
3. `pen_settings_panel.dart` - Kontrol et ve düzelt
4. `ai_assistant_panel.dart` - Tüm hardcoded renkleri değiştir
5. `shape_panel.dart` - Kontrol et
6. `text_style_panel.dart` - Kontrol et
7. `sticker_panel.dart` - Kontrol et

### Adım 3: Widget'ları Düzelt

1. `page_navigator.dart` - Bottom sheet ve list tile'ları düzelt

### Adım 4: example_app Düzelt

1. `settings_tile.dart`
2. `document_card.dart`
3. (Opsiyonel) Auth ekranları

### Adım 5: Test Et

**Light Mode Testi:**
1. Ayarlardan "Açık" tema seç
2. Canvas aç
3. Tüm toolbar butonlarına tıkla, panel'leri aç
4. Page navigator'ı aç
5. Renklerin doğru göründüğünü kontrol et

**Dark Mode Testi:**
1. Ayarlardan "Koyu" tema seç
2. Aynı adımları tekrarla
3. Okunabilirlik ve kontrast kontrol et

### Adım 6: Commit ve Push
```bash
git add .
git commit -m "fix(theme): apply dark mode to all panels and modals

- highlighter_settings_panel: replace hardcoded colors with theme
- eraser_settings_panel: replace hardcoded colors with theme
- pen_settings_panel: theme-aware colors
- ai_assistant_panel: theme-aware colors
- page_navigator: theme-aware bottom sheet
- settings_tile: theme-aware colors
- document_card: theme-aware colors"

git push origin fix/dark-mode-panels
```

---

## ⚠️ DİKKAT EDİLECEKLER

1. **DrawingTheme vs ColorScheme:** 
   - drawing_ui paketinde `DrawingTheme.of(context)` kullanılabilir
   - example_app'te `Theme.of(context).colorScheme` kullan

2. **Opacity/Alpha:**
   - `Colors.grey.withOpacity(0.5)` → `colorScheme.outline.withOpacity(0.5)`
   - Alpha değerlerini koru

3. **Conditional Dark Check:**
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
// Sadece gerektiğinde kullan
```

4. **Test Cihazları:**
   - Tablet (öncelikli)
   - Telefon

---

## ✅ TAMAMLANMA KRİTERLERİ

- [ ] Tüm panel'ler dark mode'da okunabilir
- [ ] Tüm modal'lar dark mode'da düzgün görünüyor
- [ ] Page navigator dark mode'da çalışıyor
- [ ] Settings tile'lar dark mode'da düzgün
- [ ] Document card'lar dark mode'da düzgün
- [ ] Light mode bozulmadı
- [ ] Commit yapıldı
- [ ] Branch push edildi

---

*Bu döküman Senior Architect tarafından hazırlanmıştır. Sorularınız için Product Owner'a (İlyas) danışın.*
