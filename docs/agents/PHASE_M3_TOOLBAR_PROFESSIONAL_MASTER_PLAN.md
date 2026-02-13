# PHASE M3 — TOOLBAR PROFESYONELLEŞTİRME MASTER PLAN

> **Hedef:** GoodNotes kalitesinde profesyonel toolbar, çalışan tüm özellikler, okuyucu modu, sayfa navigasyonu
> **Branch:** `feature/toolbar-professional`
> **Tahmini süre:** 5-7 gün
> **Referans:** docs/agents/GOODNOTES_UI_REFERENCE.md + goodnotes_01-04 görselleri

---

## MEVCUT DURUM ANALİZİ

### TopNavigationBar (Row 1) — Sorunlar
1. **Placeholder butonlar:** Okuyucu modu, katmanlar, belge menüsü hepsi `_showPlaceholder` çağırıyor — hiçbiri çalışmıyor
2. **İkonlar:** Generic Material Icons (home_rounded, menu_book_outlined, layers_outlined vs.)
3. **_NavButton boyutu:** 32x32dp — touch target yetersiz (M1'de fix edilmiş olabilir kontrol et)
4. **Export/Share:** PDF export dialog var ama akış iyileştirilebilir
5. **Sayfa navigasyonu:** Sidebar açmadan sayfa geçişi yok

### ToolBar (Row 2) — Sorunlar
1. **İkonlar:** Material Icons — pen, highlighter, eraser hepsi generic
2. **Kalem grubu:** 7 pen tool tek ikon altında gruplanmış ama ikon pen'i temsil etmiyor
3. **Tool button stili:** Seçili araç vurgulama var ama GoodNotes'taki mavi circle kadar net değil
4. **QuickAccessRow:** Çalışıyor ama renk daireleri ve kalınlık noktaları daha iyi olabilir

### Eksik Özellikler
1. **Okuyucu modu:** Toolbar gizle, sadece navigate — GoodNotes'taki gibi (goodnotes_04_readonly_mode.jpeg)
2. **Sayfa geçişi:** Swipe dışında alt bar veya ok butonları ile sayfa geçişi yok
3. **Page indicator:** Mevcut sayfa numarası gösterimi yok (GoodNotes'ta "Page 1/2" bar var)

---

## 6 ADIMLIK PLAN

### ADIM 1: İkon Sistemi Modernizasyonu
**Dosyalar:** Yeni icon dosyası + tüm toolbar/nav widget'ları güncelle
**İçerik:**
- Phosphor Icons veya Lucide Icons paketi ekle (pub.dev'den) — ince outline stil, GoodNotes estetiğine en yakın
- VEYA: Custom SVG icon set oluştur (flutter_svg ile)
- StarNoteIcons sınıfı oluştur — tüm ikonları tek yerden yönet
- Tüm Material Icons referanslarını StarNoteIcons ile değiştir:
  - TopNavigationBar: home, book, layers, grid, settings, export, more, search
  - ToolBar: pen (dolma kalem), pencil, ballpoint, gel, brush, highlighter, eraser, shapes, text, image, lasso, sticker, laser, selection
  - Paneller: close, check, add, remove, color wheel, thickness
- İkon boyutları standartlaştır: nav=20dp, tool=22dp, panel=18dp

**GoodNotes İkon Referansı (goodnotes_01 görselinden):**
Row 1 ikonları: ince outline stil, 20dp, tek renk
Row 2 ikonları: pen/eraser/highlighter gibi araçlar gerçekçi ikon (kalem şekli, silgi şekli), aktif olan mavi daire içinde

**Karar noktası:** Phosphor Icons paketi mi, custom SVG mi?
- Phosphor Icons avantajı: 6000+ ikon, ince stil, hemen kullanılabilir, pub.dev'de mevcut
- Custom SVG avantajı: Birebir GoodNotes tarzı, benzersiz
- **Önerim:** Phosphor Icons ile başla, gerekirse kritik ikonları (pen types, eraser) custom SVG ile değiştir

### ADIM 2: TopNavigationBar Profesyonelleştirme
**Dosyalar:** top_navigation_bar.dart tamamen refactor
**İçerik:**
- Sol bölge: Home (çalışır) + Sidebar toggle + Doküman başlığı (dropdown ok ile)
- Orta bölge: Search (arama açılabilir) 
- Sağ bölge: Okuyucu modu toggle + Katmanlar + Grid toggle + Share/Export + More menüsü
- More menüsü içeriği: Sayfa ayarları, Şablon değiştir, Yardım
- Tüm placeholder'lar kaldırılacak — her buton ya çalışacak ya da kaldırılacak
- _NavButton → yeni StarNoteNavButton: 48dp touch target, hover/pressed state, tooltip

**GoodNotes Row 1 referansı (goodnotes_01):**
```
[Home] [Sidebar] [Search] [AI] [Template] | [Pen✓] [Text] [Sticker] [Image] [Shapes] [Link] [Comment] [Mic] | [+] [Share] [More]
```

**Bizim Row 1 (hedef):**
```
[Home] [Sidebar] [Başlık ▼] [Search] | spacer | [Okuyucu] [Katmanlar] [Grid] [Share] [More]
```

### ADIM 3: ToolBar İkon ve Stil Güncellemesi
**Dosyalar:** tool_bar.dart, tool_button.dart, quick_access_row.dart
**İçerik:**
- ToolButton yeni stil: seçili araç = mavi daire arka plan (GoodNotes tarzı)
- Pen group ikonu: gerçek dolma kalem şekli (aktif pen type'a göre değişir)
- Highlighter ikonu: gerçek fosforlu kalem şekli
- Eraser ikonu: gerçek silgi şekli
- QuickAccessRow: renk daireleri daha büyük (28dp), kalınlık gösterimi çizgi preview olarak
- Çizgi stili gösterimi: düz/kesik/noktalı preview (GoodNotes Row 2'deki gibi)
- Tool button spacing ve padding iyileştirmesi

### ADIM 4: Okuyucu Modu (Read-Only Mode)
**Dosyalar:** Yeni reader_mode_provider.dart + drawing_screen.dart güncelle
**İçerik:**
- ReaderMode provider (on/off)
- Aktif olduğunda:
  - Row 2 (ToolBar) tamamen gizlenir (AnimatedContainer height 0)
  - Row 1 sadeleşir: Home + Başlık + "Salt okunur" badge + Share + More
  - Canvas tam ekran
  - Çizim devre dışı (gesture handler ignore)
  - Sayfa geçişi swipe ile aktif
- TopNavigationBar'daki "Okuyucu modu" butonu toggle yapar
- Animasyonlu geçiş (toolbar fade out/in)

**GoodNotes referansı (goodnotes_04_readonly_mode.jpeg):**
```
[Home] [Sidebar] [Search] [AI] [📖 Salt okunur] | [+] [Share] [More]
```

### ADIM 5: Page Navigator + Sayfa Göstergesi
**Dosyalar:** Yeni page_indicator_bar.dart + page_navigation widget'ları
**İçerik:**
- Canvas alt kısmında sayfa göstergesi: "Sayfa 1/5" + sol/sağ ok butonları
- GoodNotes'taki teal renk bar (goodnotes_01'de "Page 1/2" görünüyor)
- Tıklanabilir: sayfa numarasına tap → "Sayfaya git" dialog
- Ok butonları ile önceki/sonraki sayfaya geçiş
- Swipe ile sayfa geçişi (mevcut davranış korunur)
- Mini sayfa preview: uzun basınca mevcut sayfanın thumbnail'ı gösterilir
- Page indicator visibility: ToolBar settings'ten açılıp kapatılabilir
- Otomatik gizlenme: 3 saniye hareketsizlik sonrası fade out, dokunma ile tekrar görünür

**Alternatif:** Page indicator'ı TopNavigationBar'ın sağına da koyabiliriz (GoodNotes'ta sidebar içinde "1/2" yazıyor).

### ADIM 6: Final Polish + Kapsamlı Test
**İçerik:**
- Tüm butonların çalıştığını doğrula (placeholder kalmamış olmalı)
- Dark mode'da tüm yeni ikonlar düzgün görünüyor mu
- Responsive: expanded/medium/compact tüm toolbar'larda yeni ikonlar doğru mu
- Tablet + phone test
- Accessibility: tooltip'ler, semantic labels
- 30+ yeni test
- Code review: hardcoded renk, barrel exports, dosya boyutu
- drawing_screen.dart hâlâ ≤300 satır mı kontrol

---

## İKON HARİTASI

### TopNavigationBar İkonları
```
Mevcut Material Icon       → Yeni İkon (Phosphor/Custom)
─────────────────────────────────────────────────
Icons.home_rounded         → house (outline, ince)
Icons.menu_book_outlined   → book_open (okuyucu modu)
Icons.layers_outlined      → stack (katmanlar)
Icons.grid_on/grid_off     → grid_four / grid_four_slash
Icons.share_outlined       → share_network veya export
Icons.settings_outlined    → gear_six
Icons.search               → magnifying_glass
Icons.more_horiz           → dots_three
Icons.keyboard_arrow_down  → caret_down
```

### ToolBar İkonları
```
ToolType               Mevcut İkon              → Yeni İkon
────────────────────────────────────────────────────────────
pen/pencil/ballpoint   Icons.edit               → pen_nib (dolma kalem) / pencil_simple / pen
hardPencil             Icons.edit               → pencil_line
gelPen                 Icons.edit               → pen
dashedPen              Icons.edit               → pen dashed variant
brushPen               Icons.brush              → paint_brush
rulerPen               Icons.straighten         → ruler
highlighter            Icons.highlight          → highlighter_circle
neonHighlighter        Icons.highlight          → highlighter neon variant
eraser (pixel/stroke)  Icons.cleaning_services  → eraser
lassoEraser            Icons.cleaning_services  → eraser + selection
shapes                 Icons.crop_square        → shapes / square + circle overlay
text                   Icons.text_fields        → text_t / text_aa
image                  Icons.image              → image_square
sticker                Icons.emoji_emotions     → sticker / smiley
laserPointer           Icons.flashlight_on      → cursor_click / laser
selection/lasso        Icons.select_all         → selection / lasso
panZoom                Icons.pan_tool           → hand / arrows_out
settings               Icons.tune               → sliders_horizontal
```

---

## KRİTİK KURALLAR

1. **Her buton ÇALIŞMALI** — placeholder yok, ya implement et ya kaldır
2. **İkonlar tutarlı** — tüm ikonlar aynı stil (ince outline, tek renk, aynı çizgi kalınlığı)
3. **Touch target 48dp** — tüm interaktif elementler
4. **Tema uyumlu** — dark/light mode'da ikonlar doğru renk
5. **Responsive** — expanded/medium/compact toolbar'larda ikonlar doğru
6. **Performance** — SVG kullanılırsa cache'lenmeli
7. **Max 300 satır/dosya**
8. **Barrel exports eksiksiz**

---

## ÖNCELİK SIRASI

En kritik → En az kritik:
1. İkon sistemi (Adım 1) — her şeyin temeli
2. Toolbar stil güncellemesi (Adım 3) — en görünür değişiklik
3. TopNav profesyonelleştirme (Adım 2) — placeholder'ları temizle
4. Okuyucu modu (Adım 4) — yeni özellik, GoodNotes referansı
5. Page navigator (Adım 5) — kullanılabilirlik artışı
6. Final polish (Adım 6) — kalite güvence

Adım 1 ve 3 paralel yapılabilir, 2 ve 4 sıralı olmalı.
