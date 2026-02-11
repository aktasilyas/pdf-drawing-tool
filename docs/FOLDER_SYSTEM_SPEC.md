# 📂 StarNote Klasör Sistemi - Yeni Spec

> **Tarih:** 3 Şubat 2026  
> **Referans:** Samsung Notes folder system  
> **Onay:** İlyas (Product Owner)

---

## 1. Klasör Hiyerarşisi (2 Seviye Max)

### Kurallar
- **Seviye 1:** Root klasörler (parentId = null)
- **Seviye 2:** Alt klasörler (parentId = bir root klasör ID'si)
- **Seviye 3+:** YASAK — alt klasörün altına klasör oluşturulamaz
- Bir not sadece bir klasörde olabilir (veya hiçbir klasörde = root)

### Sidebar Görünümü
```
📁 İş Notları              ← Seviye 1 (root)
   📁 Toplantılar          ← Seviye 2 (indent'li)
   📁 Projeler             ← Seviye 2 (indent'li)
📁 Kişisel                 ← Seviye 1 (root)
   📁 Tarifler             ← Seviye 2 (indent'li)
📁 Okul                    ← Seviye 1 (root)
```

### Validation
- Klasör oluşturulurken parent'ın seviyesini kontrol et
- Parent zaten bir alt klasörse (parentId != null) → yeni alt klasör oluşturmayı engelle
- Hata mesajı: "Alt klasörlerin altına klasör oluşturulamaz"

### Folder Model Güncelleme
```dart
class Folder {
  final String id;
  final String name;
  final String? parentId;     // null = root klasör
  final Color color;          // AppColors.folderColors'dan
  final int sortOrder;        // Manuel sıralama için (YENİ)
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// Bu klasör alt klasör mü?
  bool get isSubfolder => parentId != null;
  
  /// Bu klasörün altına alt klasör eklenebilir mi?
  /// Sadece root klasörlere (parentId == null) eklenebilir
  bool get canHaveSubfolders => parentId == null;
}
```

---

## 2. Breadcrumb Navigation (Path Gösterimi)

### Davranış
- Klasöre girildiğinde üstte breadcrumb path gösterilir
- Her segment tıklanabilir (geri dönüş)
- Samsung'dan FARKLI ve DAHA İYİ: Samsung'da breadcrumb yok, biz ekliyoruz

### Görünüm
```
┌─────────────────────────────────────────────┐
│  ← Belgelerim > İş Notları > Toplantılar   │
└─────────────────────────────────────────────┘
```

### Senaryolar
| Konum | Breadcrumb |
|-------|-----------|
| Root (Tüm Notlar) | Gösterilmez |
| Root klasör içinde | `← Belgelerim > İş Notları` |
| Alt klasör içinde | `← Belgelerim > İş Notları > Toplantılar` |

### Widget: `BreadcrumbNavigation`
```dart
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final ValueChanged<BreadcrumbItem> onTap;
  
  // items örnek:
  // [
  //   BreadcrumbItem(id: null, label: "Belgelerim"),
  //   BreadcrumbItem(id: "folder1", label: "İş Notları"),
  //   BreadcrumbItem(id: "folder2", label: "Toplantılar"),  // current
  // ]
}

class BreadcrumbItem {
  final String? folderId;  // null = root
  final String label;
}
```

### Tasarım
- Font: bodyMedium, textSecondary renk
- Aktif (son) segment: textPrimary, fontWeight.w600
- Ayraç: " > " (chevron_right icon, 16px)
- Geri butonu: ← (leading, tıklayınca bir üst seviye)
- Horizontal scroll (çok uzunsa)

---

## 3. Favorileri Üste Sabitle (Pin Favorites to Top)

### Davranış
- Settings veya Documents header'dan toggle: "Favorileri üste sabitle"
- Aktifken: her view'da (Grid/List) favori notlar üstte ayrı section'da gösterilir
- Deaktifken: favoriler normal sıralamada karışık gösterilir

### Görünüm (aktifken)
```
┌─────────────────────────────┐
│  ⭐ Favoriler (3)           │  ← AppSectionHeader
│  ┌───┐ ┌───┐ ┌───┐        │
│  │ ★ │ │ ★ │ │ ★ │        │  ← Favori notlar
│  └───┘ └───┘ └───┘        │
│─────────────────────────────│  ← AppDivider
│  📄 Tüm Notlar (12)        │  ← AppSectionHeader
│  ┌───┐ ┌───┐ ┌───┐        │
│  │   │ │   │ │   │        │  ← Normal notlar
│  └───┘ └───┘ └───┘        │
└─────────────────────────────┘
```

### Persistence
- SharedPreferences: `pinFavoritesToTop` (bool, default: false)
- Provider: `pinFavoritesProvider`

---

## 4. Çöp Kutusu (30 Gün Retention)

### Kurallar
- Silinen not → `deletedAt` timestamp eklenir → Çöp Kutusu'na taşınır
- 30 gün sonra otomatik kalıcı silme
- Kullanıcı manuel olarak "Kalıcı Sil" veya "Geri Yükle" yapabilir
- Çöp Kutusu header'da kalan gün gösterilir

### Document Model Güncelleme
```dart
class DocumentInfo {
  // ... mevcut alanlar
  final DateTime? deletedAt;    // YENİ - null ise silinmemiş
  
  /// Kalıcı silinecek tarih
  DateTime? get permanentDeleteDate => 
    deletedAt?.add(const Duration(days: 30));
  
  /// Kalan gün
  int? get daysUntilPermanentDelete {
    if (deletedAt == null) return null;
    final remaining = permanentDeleteDate!.difference(DateTime.now()).inDays;
    return remaining.clamp(0, 30);
  }
}
```

### Çöp Kutusu UI
- Her not kartında: "X gün kaldı" badge
- Header: "30 gün sonra kalıcı olarak silinir" info text
- Actions: "Geri Yükle" + "Kalıcı Sil"
- Toplu: "Çöpü Boşalt" butonu

### Klasör Silindiğinde
- İçindeki tüm notlar Çöp Kutusu'na taşınır
- Alt klasörleri de silinir
- Alt klasörlerdeki notlar da Çöp Kutusu'na

---

## 5. Klasör Manuel Sıralama (Drag & Drop)

### Nerede?
- "Klasörleri Yönet" ekranı (ayrı sayfa veya modal)
- Sidebar'da "Klasörler" section header'ın trailing'inde "Yönet" butonu

### Davranış
- Her klasör satırının sağında drag handle (≡ icon)
- Long-press + drag ile sıra değiştir
- Root klasörler kendi aralarında sıralanır
- Alt klasörler parent içinde kendi aralarında sıralanır
- Değişiklikler anında kaydedilir

### Manage Folders Ekranı
```
┌──────────────────────────────────────┐
│  ← Klasörleri Yönet                 │
│──────────────────────────────────────│
│  🔴 İş Notları            ≡  ⋯     │  ← Root, drag handle + menu
│     🔵 Toplantılar        ≡  ⋯     │  ← Alt klasör (indent'li)
│     🟢 Projeler           ≡  ⋯     │  ← Alt klasör (indent'li)
│  🟡 Kişisel               ≡  ⋯     │  ← Root
│     🟣 Tarifler           ≡  ⋯     │  ← Alt klasör
│  🔵 Okul                  ≡  ⋯     │  ← Root
│──────────────────────────────────────│
│  + Yeni Klasör                       │
└──────────────────────────────────────┘
```

### Menü (⋯) Seçenekleri
- Yeniden Adlandır
- Renk Değiştir
- Alt Klasör Ekle (sadece root'ta)
- Sil

### sortOrder Mantığı
```dart
// Her klasörde sortOrder alanı (int)
// Drag sonrası tüm sıralar güncellenir
// Root: sortOrder 0, 1, 2, ...
// Alt: kendi parent içinde sortOrder 0, 1, 2, ...
```

---

## 6. Tags Sistemi (Hashtag Tabanlı)

### Kurallar
- Her nota birden fazla tag eklenebilir
- Format: # prefix (örn: #iş, #okul, #önemli)
- Sidebar'da "Etiketler" bölümü
- Tag'e tıklayınca o tag'e sahip tüm notlar listelenir
- Search'te tag ile filtreleme

### Document Model Güncelleme
```dart
class DocumentInfo {
  // ... mevcut alanlar
  final List<String> tags;     // YENİ - ["iş", "toplantı", "önemli"]
}
```

### Tag Ekleme UI
- Not düzenleme ekranında: AppBar'da tag ikonu
- Tıklayınca: tag input modal
- Mevcut tag'ler chip olarak gösterilir (silinebilir)
- Yeni tag yazılabilir (autocomplete mevcut tag'lerden)

### Sidebar Tags Bölümü
```
──────────────────────
📌 Etiketler            ← AppSectionHeader
  # iş (5)              ← tag + not sayısı
  # okul (3)
  # önemli (7)
  # kişisel (2)
──────────────────────
```

### Tags Provider
```dart
// Tüm unique tag'leri getir
final allTagsProvider = FutureProvider<List<TagInfo>>(...);

// Belirli tag'e sahip notları getir
final documentsByTagProvider = FutureProvider.family<List<DocumentInfo>, String>(...);

class TagInfo {
  final String name;
  final int documentCount;
}
```

### ÖNCELİK NOTU
Tags sistemi Phase 7'nin son part'ı olarak veya ayrı bir phase olarak implement edilebilir. Çünkü:
- Supabase schema değişikliği gerektirir (tags kolonu veya ayrı tablo)
- Editor ekranına da entegre edilmesi gerekir
- Arama sistemi güncellenmeli

Öneri: Phase 7'de sidebar'da "Etiketler" bölümünü placeholder olarak ekle, asıl implementasyonu Phase 8 veya ayrı bir task olarak yap.

---

## 7. Sidebar Güncel Yapı (Final)

```
┌──────────────────────────────────────┐
│  ★ StarNote          ⚙️             │  ← Logo + Settings
│──────────────────────────────────────│
│  🔍 Not ara...                       │  ← AppSearchField
│──────────────────────────────────────│
│  📄 Tüm Notlar              (24)    │  ← Selected: primary bg
│  ⭐ Favoriler                 (3)    │
│  🗑️ Çöp Kutusu               (2)    │
│──────────────────────────────────────│  ← AppDivider
│  KLASÖRLER                 Yönet    │  ← AppSectionHeader + trailing
│  🔴 İş Notları              (8)     │
│     🔵 Toplantılar          (3)     │  ← indent'li alt klasör
│     🟢 Projeler             (5)     │
│  🟡 Kişisel                 (4)     │
│  🔵 Okul                    (6)     │
│  + Yeni Klasör                       │
│──────────────────────────────────────│  ← AppDivider
│  ETİKETLER                          │  ← AppSectionHeader
│  # iş                       (5)     │
│  # okul                     (3)     │
│  # önemli                   (7)     │
└──────────────────────────────────────┘
```

---

## 8. Özet: Değişiklik Listesi

| # | Değişiklik | Etki Alanı | Öncelik |
|---|-----------|------------|---------|
| 1 | 2 seviye klasör limiti | Folder model + create logic | 🔴 P0 |
| 2 | Breadcrumb navigation | Documents screen header | 🔴 P0 |
| 3 | Pin favorites to top | Documents screen + settings | 🟡 P1 |
| 4 | Çöp kutusu 30 gün | Document model + trash logic | 🟡 P1 |
| 5 | Klasör manuel sıralama | Manage Folders screen | 🟡 P1 |
| 6 | Tags sistemi | Model + UI + Supabase | 🟢 P2 |

---

**Hazırlayan:** Claude (Senior Architect)  
**Onaylayan:** İlyas (Product Owner)  
**Tarih:** 3 Şubat 2026
