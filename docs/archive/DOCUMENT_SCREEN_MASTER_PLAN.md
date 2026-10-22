# 📋 DOCUMENT SCREEN MASTER PLAN

> **Oluşturulma:** 2025-01-25
> **Son Güncelleme:** 2025-01-25 (Gece)
> **Amaç:** Documents ekranını tamamen işlevsel hale getirmek
> **Kural:** Her özellik branch'te geliştirilir, test edilir, main'e merge edilir

---

## 🎯 GENEL BAKIŞ

Documents ekranı sol menüde şu bölümleri içeriyor:

| Bölüm | Mevcut Durum | Hedef |
|-------|--------------|-------|
| Tüm Notlar | ✅ Çalışıyor | ✅ |
| Son Kullanılanlar | ✅ Çalışıyor | ✅ |
| Favoriler | ✅ Çalışıyor | ✅ |
| Klasörler | ✅ Çalışıyor | ✅ |
| Çöp Kutusu | ✅ Çalışıyor | ✅ |
| Şablonlar | ⏳ UI var | İçerik + Premium |
| Ayarlar | ✅ Tamamlandı | ✅ |

---

## ✅ TAMAMLANAN: SETTINGS & DARK MODE

**Branch:** `fix/theme-modal-divider`
**Durum:** ✅ Tamamlandı (25 Ocak 2025)

### Settings Infrastructure ✅
- [x] Branch oluştur
- [x] Klasör yapısı
- [x] AppSettings entity
- [x] SettingsProvider (SharedPreferences)
- [x] Widget'lar (SettingsSection, SettingsTile, ProfileHeader)
- [x] SettingsScreen ana UI
- [x] Route entegrasyonu
- [x] Documents ekranından erişim
- [x] Test ve commit

### Dark Mode Tema Uyumluluğu ✅
- [x] Main App - Theme mode selection (light/dark/system)
- [x] Documents Screen - Sidebar, header, divider'lar
- [x] Editor Screen - Toolbar, modallar, dialog'lar
- [x] Drawing UI Components:
  - [x] Tool panels (pen, highlighter, eraser settings)
  - [x] Color picker (unified + compact)
  - [x] Page navigator
  - [x] Floating pen box
  - [x] Tool buttons
  - [x] Page thumbnails
- [x] New Document Dialog - Modal, dropdown, input
- [x] Document Card - Title, date, chevron
- [x] Tüm modallar ve dialog'lar
- [x] Error state'ler ve loading indicator'lar

### Detaylı Değişiklikler
```
✅ Documents Screen:
   - Sidebar: surfaceVariant background, tema renkleri
   - Header: onSurface text, theme buttons, divider
   - Document cards: onSurface title, onSurfaceVariant date
   - Dividers: Gradient (alpha: 0.3/0.5)

✅ Editor Screen:
   - Toolbar: Dynamic DrawingTheme (surfaceContainerHighest)
   - Modallar: tema background, border, text colors
   - Dialog'lar: tema uyumlu input, button, error colors

✅ Drawing UI:
   - DrawingScreen: Theme-aware DrawingTheme generation
   - Tool buttons: primary, onSurfaceVariant colors
   - Pen box: surfaceContainer bg, tema icons
   - Color picker: primary, outline, surface colors
   - Page navigator: outlineVariant borders, shadows
   - Page thumbnails: primary border (selected), outline (unselected)

✅ Modal & Dialogs:
   - New document: surfaceContainerHighest (dark)
   - Bottom sheets: tema background
   - TextField: surfaceContainerHigh fill, outline border
   - Buttons: FilledButton (tema otomatik)
```

---

## 📦 PHASE 2: TEMPLATES (Şablonlar)

**Branch:** `feature/template-data-integration`
**Durum:** ✅ TAMAMLANDI (31 Ocak 2025)
**Öncelik:** Yüksek → Tamamlandı

### Şablon Kategorileri ✅
- [x] Boş (Free)
- [x] Çizgili (Free)
- [x] Kareli (Free)
- [x] Noktalı (Premium)
- [x] Cornell Notes (Premium)
- [x] To-Do List (Premium)
- [x] Meeting Notes (Premium)
- [x] Weekly Planner (Premium)

### Şablon Önizleme ✅
- [x] Thumbnail görselleri
- [x] Önizleme modalı
- [x] Premium badge overlay

### Şablon Seçimi ✅
- [x] Not defteri oluştururken şablon seç
- [x] Mevcut nota şablon uygula
- [x] Favori şablonlar

### Kapak Sistemi ✅
- [x] 10 kapak tasarımı (6 free, 4 premium gradient)
- [x] Kapak önizleme widget
- [x] Kapak toggle (açık/kapalı)
- [x] Format seçici (A4/A5/Letter + Dikey/Yatay)
- [x] Kağıt rengi seçimi (6 renk)

### Performans İyileştirmeleri ✅
- [x] Pattern rendering Picture caching (50-100x hızlanma)
- [x] RepaintBoundary optimizasyonu
- [x] Whiteboard direkt erişim
- [x] Dinamik zoom limitleri (%5-%1000)

---

## 📦 PHASE 3: PREMIUM ENTEGRASYONU

**Branch:** `feature/premium-integration`
**Durum:** 🔵 Proje bitiminde yapılacak
**Öncelik:** Ertelenmiş

### Premium Provider
- [ ] RevenueCat entegrasyonu kontrol
- [ ] isPremium provider
- [ ] Premium features listesi

### UI Kısıtlamaları
- [ ] Free user'a premium özellik göster (kilitli)
- [ ] "Premium'a Geç" banner
- [ ] Özellik bazlı kilit ikonu

### Premium Özellikler
- [ ] Sınırsız PDF import
- [ ] Tüm şablonlar
- [ ] Cloud sync
- [ ] Profil fotoğrafı
- [ ] Reklamsız deneyim
- [ ] AI Asistan (ileride)

### Satın Alma Flow
- [ ] Paket seçimi ekranı
- [ ] Aylık/Yıllık seçenekler
- [ ] Satın alma işlemi
- [ ] Restore purchases

**NOT:** Premium sistemi altyapıda hazır, UI entegrasyonu proje tamamlandıktan sonra yapılacak.

---

## 📦 PHASE 4: DOCUMENT LİSTE İYİLEŞTİRMELERİ

**Branch:** `feature/document-list-improvements`
**Durum:** 🔄 AKTİF (31 Ocak 2025)
**Öncelik:** 🔴 YÜKSEK

### Görünüm Seçenekleri
- [ ] Grid view (mevcut)
- [ ] List view
- [ ] Görünüm toggle butonu
- [ ] Tercih kaydetme

### Sıralama
- [ ] Tarihe göre (yeni → eski)
- [ ] Tarihe göre (eski → yeni)
- [ ] İsme göre (A-Z)
- [ ] İsme göre (Z-A)
- [ ] Boyuta göre

### Arama
- [ ] Arama çubuğu
- [ ] Başlığa göre arama
- [ ] İçeriğe göre arama (Premium)
- [ ] Arama geçmişi

### Toplu İşlemler
- [ ] Çoklu seçim modu
- [ ] Toplu silme
- [ ] Toplu taşıma
- [ ] Toplu favorilere ekleme

---

## 📦 PHASE 5: RESPONSIVE TASARIM

**Branch:** `feature/responsive-design`
**Durum:** ⏳ Bekliyor

### Breakpoints
- [ ] Mobile (<600px): Drawer menü
- [ ] Tablet (600-1200px): Rail + içerik
- [ ] Desktop (>1200px): Sidebar + içerik

### Adaptive Widgets
- [ ] NavigationRail (tablet)
- [ ] NavigationDrawer (mobile)
- [ ] Sidebar (desktop)
- [ ] Grid column sayısı

### Orientation
- [ ] Portrait desteği
- [ ] Landscape desteği
- [ ] Orientation change handling

---

## 📦 PHASE 6: SYNC (Senkronizasyon)

**Branch:** `feature/cloud-sync`
**Durum:** ⏳ Bekliyor (Premium)

### Supabase Storage
- [ ] Belge upload
- [ ] Belge download
- [ ] Conflict resolution

### Sync Logic
- [ ] Offline-first yaklaşım
- [ ] Background sync
- [ ] Sync status indicator
- [ ] Manuel sync butonu

### Multi-device
- [ ] Cihaz listesi
- [ ] Son sync zamanı
- [ ] Cihaz bazlı çakışma çözümü

---

## 📝 AKTİF GÖREVLER (31 Ocak 2025)

### 🔴 Öncelik 1: Document Liste İyileştirmeleri (Bu Hafta)
- [ ] Grid/List view toggle butonu ekle (header'a)
- [ ] Görünüm tercihi kaydetme (SharedPreferences)
- [ ] Sıralama dropdown menüsü
  - [ ] Tarihe göre (Yeni → Eski) - default
  - [ ] Tarihe göre (Eski → Yeni)
  - [ ] İsme göre (A-Z)
  - [ ] İsme göre (Z-A)
  - [ ] Boyuta göre
- [ ] Arama çubuğu implementation
  - [ ] SearchBar widget ekle
  - [ ] Başlığa göre filtreleme
  - [ ] Real-time arama
- [ ] List view tasarımı (DocumentListTile widget)
- [ ] Grid/List geçiş animasyonu

### 🟡 Öncelik 2: Toplu İşlemler (Sonrası)
- [ ] Çoklu seçim modu
- [ ] Toplu silme
- [ ] Toplu taşıma
- [ ] Toplu favorilere ekleme

### 🟢 Öncelik 3: İlerideki İyileştirmeler
- [ ] İçeriğe göre arama (Premium)
- [ ] Arama geçmişi
- [ ] Filtreleme (Klasör, Tarih aralığı, Etiket)

---

## 🔧 TEKNİK KURALLAR

### Branch Stratejisi
```
main (production ready)
  └── feature/settings-infrastructure
  └── feature/templates
  └── feature/premium-integration
  └── feature/document-list-improvements
  └── feature/responsive-design
  └── feature/cloud-sync
```

### Commit Mesajları
```
feat(settings): add theme selection
fix(templates): resolve premium badge overlay
refactor(documents): improve grid performance
test(settings): add unit tests for provider
```

### PR Checklist
- [ ] Kod çalışıyor
- [ ] Responsive test edildi (mobile + tablet)
- [ ] Premium/Free durumları test edildi
- [ ] Mevcut özellikler bozulmadı
- [ ] Commit mesajları anlamlı

---

## 📊 PREMIUM vs FREE MATRİX

| Özellik | Free | Premium |
|---------|------|---------|
| Belge oluşturma | ✅ Sınırsız | ✅ |
| Temel şablonlar (3) | ✅ | ✅ |
| Premium şablonlar | ❌ | ✅ |
| PDF Import | ✅ 5 sayfa | ✅ Sınırsız |
| Cloud Sync | ❌ | ✅ |
| Profil fotoğrafı | ❌ | ✅ |
| İçerik arama | ❌ | ✅ |
| AI Asistan | ❌ | ✅ |
| Reklamsız | ❌ | ✅ |

---

## 📅 TAHMİNİ ZAMAN ÇİZELGESİ

| Phase | Tahmini Süre | Öncelik | Durum |
|-------|--------------|---------|-------|
| Settings | 2-3 gün | 🔴 Yüksek | ✅ Tamamlandı |
| Templates | 4-5 gün | 🔴 Yüksek | ✅ Tamamlandı |
| Liste İyileştirme | 2-3 gün | 🔴 Yüksek | 🔄 Aktif |
| Responsive | 1-2 gün | 🟡 Orta | ⏳ Sonra |
| Toplu İşlemler | 1 gün | 🟡 Orta | ⏳ Sonra |
| Premium | 2-3 gün | 🔵 Proje sonu | ⏳ Ertelenmiş |
| Sync | 3-5 gün | 🔵 Proje sonu | ⏳ Ertelenmiş |

---

*Bu plan her session başında gözden geçirilmeli ve ilerleme işaretlenmeli.*

---

## 📊 İLERLEME DURUMU

### ✅ Tamamlanan Fazlar (31 Ocak 2025)
- **Phase 1: Settings & Dark Mode** ✅ (25 Ocak 2025)
- **Phase 2: Templates & Covers** ✅ (30-31 Ocak 2025)
- **Performance Optimization** ✅ (31 Ocak 2025)

### 🔄 Aktif Faz
- **Phase 4: Document Liste İyileştirmeleri** (31 Ocak 2025 başladı)

### ⏳ Gelecek Fazlar
- Phase 5: Responsive Tasarım
- Phase 6: Toplu İşlemler
- Phase 3: Premium Entegrasyonu (Proje bitiminde)
- Phase 7: Cloud Sync (Proje bitiminde)
