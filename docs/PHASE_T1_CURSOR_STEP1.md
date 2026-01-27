# Phase T1 - Adım 1: TemplateCategory & TemplatePattern Enums

> **Branch:** feature/templates-core
> **Hedef:** Template sisteminin temel enum'larını oluştur

---

## ⚠️ BAŞLAMADAN ÖNCE

```bash
# 1. Branch oluştur
git checkout main
git pull origin main
git checkout -b feature/templates-core

# 2. Mevcut testlerin geçtiğinden emin ol
cd packages/drawing_core && flutter test
```

---

## 📁 OLUŞTURULACAK DOSYALAR

### Dosya 1: template_category.dart

**Yol:** `packages/drawing_core/lib/src/models/template_category.dart`

```dart
/// Template kategorileri.
/// 
/// Basic kategorisi Free, diğerleri Premium.
enum TemplateCategory {
  /// Boş, çizgili, kareli, noktalı - FREE
  basic,
  
  /// Cornell, To-Do, Meeting Notes - PREMIUM
  productivity,
  
  /// Storyboard, Music, Art - PREMIUM
  creative,
  
  /// Math, Handwriting, Vocabulary - PREMIUM
  education,
  
  /// Calendar, Weekly, Budget - PREMIUM
  planning,
  
  /// Isometric, Hexagonal, Engineer - PREMIUM
  special,
}

/// TemplateCategory extension methods
extension TemplateCategoryExtension on TemplateCategory {
  /// Kategori Free mi?
  bool get isFree => this == TemplateCategory.basic;
  
  /// Kategori Premium mı?
  bool get isPremium => !isFree;
  
  /// Türkçe kategori adı
  String get displayName {
    switch (this) {
      case TemplateCategory.basic:
        return 'Temel';
      case TemplateCategory.productivity:
        return 'Verimlilik';
      case TemplateCategory.creative:
        return 'Yaratıcı';
      case TemplateCategory.education:
        return 'Eğitim';
      case TemplateCategory.planning:
        return 'Planlama';
      case TemplateCategory.special:
        return 'Özel';
    }
  }
  
  /// İngilizce kategori adı
  String get displayNameEn {
    switch (this) {
      case TemplateCategory.basic:
        return 'Basic';
      case TemplateCategory.productivity:
        return 'Productivity';
      case TemplateCategory.creative:
        return 'Creative';
      case TemplateCategory.education:
        return 'Education';
      case TemplateCategory.planning:
        return 'Planning';
      case TemplateCategory.special:
        return 'Special';
    }
  }
}
```

---

### Dosya 2: template_pattern.dart

**Yol:** `packages/drawing_core/lib/src/models/template_pattern.dart`

```dart
/// Template pattern türleri.
/// 
/// Her pattern, sayfada çizilecek arka plan desenini belirler.
enum TemplatePattern {
  /// Boş sayfa - hiçbir desen yok
  blank,
  
  /// İnce çizgili (6mm spacing)
  thinLines,
  
  /// Orta çizgili (8mm spacing)
  mediumLines,
  
  /// Kalın çizgili (10mm spacing)
  thickLines,
  
  /// Küçük kareli (5mm spacing)
  smallGrid,
  
  /// Orta kareli (7mm spacing)
  mediumGrid,
  
  /// Büyük kareli (10mm spacing)
  largeGrid,
  
  /// Küçük noktalı (5mm spacing)
  smallDots,
  
  /// Orta noktalı (7mm spacing)
  mediumDots,
  
  /// Büyük noktalı (10mm spacing)
  largeDots,
  
  /// İzometrik grid (30° açılı)
  isometric,
  
  /// Altıgen grid
  hexagonal,
  
  /// Cornell notes (margin + summary)
  cornell,
  
  /// Müzik nota kağıdı (5 çizgi staff)
  music,
  
  /// El yazısı (baseline + midline)
  handwriting,
  
  /// Kaligrafi (açılı çizgiler)
  calligraphy,
}

/// TemplatePattern extension methods
extension TemplatePatternExtension on TemplatePattern {
  /// Pattern için varsayılan spacing (mm cinsinden)
  double get defaultSpacingMm {
    switch (this) {
      case TemplatePattern.blank:
        return 0;
      case TemplatePattern.thinLines:
        return 6;
      case TemplatePattern.mediumLines:
        return 8;
      case TemplatePattern.thickLines:
        return 10;
      case TemplatePattern.smallGrid:
      case TemplatePattern.smallDots:
        return 5;
      case TemplatePattern.mediumGrid:
      case TemplatePattern.mediumDots:
        return 7;
      case TemplatePattern.largeGrid:
      case TemplatePattern.largeDots:
        return 10;
      case TemplatePattern.isometric:
        return 10;
      case TemplatePattern.hexagonal:
        return 12;
      case TemplatePattern.cornell:
        return 8;
      case TemplatePattern.music:
        return 8;
      case TemplatePattern.handwriting:
        return 10;
      case TemplatePattern.calligraphy:
        return 12;
    }
  }
  
  /// Pattern için varsayılan çizgi kalınlığı (px)
  double get defaultLineWidth {
    switch (this) {
      case TemplatePattern.blank:
        return 0;
      case TemplatePattern.thinLines:
      case TemplatePattern.smallGrid:
      case TemplatePattern.smallDots:
        return 0.3;
      case TemplatePattern.mediumLines:
      case TemplatePattern.mediumGrid:
      case TemplatePattern.mediumDots:
        return 0.5;
      case TemplatePattern.thickLines:
      case TemplatePattern.largeGrid:
      case TemplatePattern.largeDots:
        return 0.7;
      default:
        return 0.5;
    }
  }
  
  /// Pattern çizgi içeriyor mu?
  bool get hasLines {
    return this == TemplatePattern.thinLines ||
           this == TemplatePattern.mediumLines ||
           this == TemplatePattern.thickLines ||
           this == TemplatePattern.cornell ||
           this == TemplatePattern.music ||
           this == TemplatePattern.handwriting ||
           this == TemplatePattern.calligraphy;
  }
  
  /// Pattern grid içeriyor mu?
  bool get hasGrid {
    return this == TemplatePattern.smallGrid ||
           this == TemplatePattern.mediumGrid ||
           this == TemplatePattern.largeGrid ||
           this == TemplatePattern.isometric ||
           this == TemplatePattern.hexagonal;
  }
  
  /// Pattern nokta içeriyor mu?
  bool get hasDots {
    return this == TemplatePattern.smallDots ||
           this == TemplatePattern.mediumDots ||
           this == TemplatePattern.largeDots;
  }
}
```

---

## 🧪 TEST DOSYASI

**Yol:** `packages/drawing_core/test/models/template_enums_test.dart`

```dart
import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('TemplateCategory', () {
    test('should have 6 categories', () {
      expect(TemplateCategory.values.length, 6);
    });
    
    test('basic should be free', () {
      expect(TemplateCategory.basic.isFree, true);
      expect(TemplateCategory.basic.isPremium, false);
    });
    
    test('non-basic categories should be premium', () {
      expect(TemplateCategory.productivity.isPremium, true);
      expect(TemplateCategory.creative.isPremium, true);
      expect(TemplateCategory.education.isPremium, true);
      expect(TemplateCategory.planning.isPremium, true);
      expect(TemplateCategory.special.isPremium, true);
    });
    
    test('displayName should return Turkish name', () {
      expect(TemplateCategory.basic.displayName, 'Temel');
      expect(TemplateCategory.productivity.displayName, 'Verimlilik');
    });
    
    test('displayNameEn should return English name', () {
      expect(TemplateCategory.basic.displayNameEn, 'Basic');
      expect(TemplateCategory.productivity.displayNameEn, 'Productivity');
    });
  });
  
  group('TemplatePattern', () {
    test('should have 16 patterns', () {
      expect(TemplatePattern.values.length, 16);
    });
    
    test('blank should have zero spacing', () {
      expect(TemplatePattern.blank.defaultSpacingMm, 0);
      expect(TemplatePattern.blank.defaultLineWidth, 0);
    });
    
    test('lined patterns should have correct spacing', () {
      expect(TemplatePattern.thinLines.defaultSpacingMm, 6);
      expect(TemplatePattern.mediumLines.defaultSpacingMm, 8);
      expect(TemplatePattern.thickLines.defaultSpacingMm, 10);
    });
    
    test('grid patterns should have correct spacing', () {
      expect(TemplatePattern.smallGrid.defaultSpacingMm, 5);
      expect(TemplatePattern.mediumGrid.defaultSpacingMm, 7);
      expect(TemplatePattern.largeGrid.defaultSpacingMm, 10);
    });
    
    test('dot patterns should have correct spacing', () {
      expect(TemplatePattern.smallDots.defaultSpacingMm, 5);
      expect(TemplatePattern.mediumDots.defaultSpacingMm, 7);
      expect(TemplatePattern.largeDots.defaultSpacingMm, 10);
    });
    
    test('hasLines should return true for lined patterns', () {
      expect(TemplatePattern.thinLines.hasLines, true);
      expect(TemplatePattern.cornell.hasLines, true);
      expect(TemplatePattern.smallGrid.hasLines, false);
    });
    
    test('hasGrid should return true for grid patterns', () {
      expect(TemplatePattern.smallGrid.hasGrid, true);
      expect(TemplatePattern.isometric.hasGrid, true);
      expect(TemplatePattern.thinLines.hasGrid, false);
    });
    
    test('hasDots should return true for dot patterns', () {
      expect(TemplatePattern.smallDots.hasDots, true);
      expect(TemplatePattern.mediumDots.hasDots, true);
      expect(TemplatePattern.smallGrid.hasDots, false);
    });
  });
}
```

---

## ✅ CHECKLIST

```
□ Branch oluşturuldu: feature/templates-core
□ template_category.dart oluşturuldu
□ template_pattern.dart oluşturuldu
□ template_enums_test.dart oluşturuldu
□ flutter analyze hata yok
□ flutter test geçiyor
```

---

## 📝 ADIM TAMAMLANINCA

```
İlyas'a bildir:
"Adım 1 tamamlandı. 
- TemplateCategory (6 kategori)
- TemplatePattern (16 pattern)
- Test: X/X geçiyor

Ready to commit? (y/n)"
```

**Commit mesajı:** `feat(core): add TemplateCategory and TemplatePattern enums`

---

*Bu adım tamamlanınca Adım 2'ye geç: Template Model*
