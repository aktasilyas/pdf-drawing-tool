# TEMPLATE ENHANCEMENT — STEP 3: Template Picker UI Güncellemesi

## BAĞLAM
Step 1-2'de 8 kategori, 28 pattern, 37 template ve 12 yapısal painter eklendi. Mevcut UI zaten CategoryTabs + TemplateGridView kullanıyor ve yeni template'lar otomatik görünüyor. Bu adımda UI iyileştirmeleri yapacağız.

## BRANCH
```bash
git checkout main
git pull origin main
git checkout -b feature/template-ui-update
```

## KRİTİK KURALLAR
1. HARD CODED RENK KULLANMA — her renk `Theme.of(context).colorScheme` veya widget parametresinden gelsin
2. SABİT PİKSEL KULLANMA — responsive olsun (MediaQuery, LayoutBuilder)
3. MOBİL UYUMLULUK — telefonda 3 sütun, tablette 5 sütun
4. Mevcut widget'ların çalışan kısımlarını BOZMA

---

## GÖREV 1: CategoryTabs'a İkon Ekle

**Dosya 1:** `packages/drawing_ui/lib/src/widgets/template_picker/category_tabs.dart`

Mevcut _CategoryChip'e ikon ekle. İkonlar TemplateCategory.iconName'den gelecek (Step 1'de eklendi).

iconName → IconData mapping'i ekle (dosyanın başına):

```dart
/// TemplateCategory.iconName → IconData mapping
IconData _categoryIcon(String iconName) {
  switch (iconName) {
    case 'description': return Icons.description_outlined;
    case 'work': return Icons.work_outline;
    case 'palette': return Icons.palette_outlined;
    case 'star': return Icons.star_outline;
    case 'calendar_today': return Icons.calendar_today_outlined;
    case 'auto_stories': return Icons.auto_stories_outlined;
    case 'school': return Icons.school_outlined;
    case 'checklist': return Icons.checklist_outlined;
    default: return Icons.description_outlined;
  }
}
```

_CategoryChip'te label'ın soluna ikon ekle:

```dart
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
```

_CategoryChip'e `final IconData? icon;` parametresi ekle.

Kullanım:
```dart
...TemplateCategory.values.map((category) => Padding(
  padding: const EdgeInsets.only(left: 8),
  child: _CategoryChip(
    label: category.displayName,
    icon: _categoryIcon(category.iconName),
    isSelected: selectedCategory == category,
    onTap: () => onCategorySelected(category),
    colorScheme: colorScheme,
  ),
)),
```

"Tümü" chip'ine icon yok (`icon: null`).

---

## GÖREV 2: TemplateCard'a Premium Badge Ekle

**Dosya 2:** `packages/drawing_ui/lib/src/widgets/template_picker/template_card.dart`

Mevcut TemplateCard widget'ına premium overlay ekle. Premium template'larda sağ üstte kilit ikonu göster.

Template model zaten `isPremium` property'sine sahip. TemplateCard'ın build metodunda preview widget'ının üstüne Stack ile badge ekle:

```dart
// Preview kısmını Stack ile sar:
Stack(
  children: [
    // Mevcut preview widget (TemplatePreviewWidget veya CustomPaint)
    existingPreviewWidget,
    
    // Premium badge (sağ üst)
    if (template.isPremium)
      Positioned(
        top: 4,
        right: 4,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.lock_outline,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
  ],
)
```

⚠️ DİKKAT: Renkler colorScheme'den gelsin. `Colors.black`, `Colors.grey` vs. KULLANMA.

---

## GÖREV 3: example_app TemplateGridView'da Premium Badge

**Dosya 3:** `example_app/lib/features/documents/presentation/widgets/template_grid.dart`

Mevcut _TemplateGridItem'da da premium badge ekle (drawing_ui'daki TemplateCard ile aynı mantık):

_TemplateGridItem'ın build metodunda Expanded içindeki Container'ı Stack ile sar:

```dart
Expanded(
  child: Stack(
    children: [
      // Mevcut Container (preview)
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : outlineColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: TemplatePreviewWidget(
          template: template,
          backgroundColorOverride: Color(paperColor),
        ),
      ),
      
      // Premium badge
      if (template.isPremium)
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ],
  ),
),
```

---

## GÖREV 4: example_app TemplateCategoryTabs'ı İkonlu Versiyona Güncelle

**Dosya 4:** `example_app/lib/features/documents/presentation/widgets/template_category_tabs.dart`

Bu dosya kendi ayrı TemplateCategoryTabs widget'ını kullanıyor (drawing_ui'dakinden farklı). Buna da ikon ekle.

Aynı `_categoryIcon` helper fonksiyonunu bu dosyaya da ekle.

Mevcut `AppChip` kullanılıyorsa ve ikon desteklemiyorsa, doğrudan custom chip yaz veya Row(icon + text) kullan:

```dart
children: TemplateCategory.values.map((category) {
  final isSelected = selectedCategory == category;
  return Padding(
    padding: const EdgeInsets.only(right: AppSpacing.sm),
    child: GestureDetector(
      onTap: () => onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(category.iconName),
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              category.displayName,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}).toList(),
```

---

## GÖREV 5: Template Selection Screen'de Responsive Grid Kontrolü

**Dosya 5:** `example_app/lib/features/documents/presentation/screens/template_selection_screen.dart`

Kontrol et: TemplateGridView'da crossAxisCount doğru hesaplanıyor mu?

Mevcut: `isPhone ? 3 : 5`

Bu yeterli ama 8 kategori, 37 template ile her kategoride az template olabilir. Eğer bir kategoride sadece 1-2 template varsa grid boş görünebilir. Kontrol:

```dart
// TemplateGridView'da: template yoksa empty state göster
if (templates.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.dashboard_customize_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text(
          'Bu kategoride şablon yok',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
```

---

## GÖREV 6: Dark Mode Kontrolü

Yaptığın tüm değişikliklerde dark mode'u kontrol et:

1. Uygulamayı dark mode'da aç
2. Template selection ekranına git
3. Kontrol:
   - Kategori tab'ları okunabilir mi?
   - İkonlar görünüyor mu?
   - Premium badge arka planı okunabilir mi?
   - Template preview'ları dark mode'da iyi görünüyor mu?
   - Seçili template border'ı belirgin mi?

Sorun varsa düzelt — renkler her zaman `colorScheme`'den gelsin.

---

## GÖREV 7: flutter analyze + test

```bash
cd packages/drawing_ui
flutter analyze
flutter test

cd ../../example_app
flutter analyze
flutter test
```

Hata yoksa İlyas'a bildir, commit için onay bekle.

**Commit mesajı:**
```
feat(ui): update template picker with icons and premium badges

- Add category icons to CategoryTabs (both drawing_ui and example_app)
- Add premium lock badge overlay to template cards
- Empty state for categories with no templates
- All colors from theme (no hard-coded values)
- Dark mode compatible
```

---

## BU ADIMDA YAPILMAYACAKLAR
- Supabase entegrasyonu (Step 4)
- Kapak görselleri (Step 5)
- Yeni widget oluşturma — mevcut widget'ları güncelle
- Template preview modal (mevcut yeterli)
