# Phase 4E-2: Pen Icon Design Specification

> **Referans:** Fenci/StarNote app pen toolbar
> **Hedef:** Premium, soft, 3D hissi veren kalem ikonları

---

## Genel Tasarım Prensipleri

### Stil Özellikleri
- **Soft shadows:** Hafif, blur'lu gölgeler (elevation hissi)
- **Gradient fills:** Düz renk yerine subtle gradient kullan
- **Rounded edges:** Tüm köşeler yuvarlatılmış, keskin kenar yok
- **3D depth:** Işık/gölge ile derinlik hissi
- **Minimal detail:** Az ama etkili detay
- **Diagonal orientation:** ~30-45° açıyla yerleşim

### Boyut ve Oran
- Canvas boyutu: 56x56 veya 64x64 piksel
- Kalem uzunluğu: Canvas'ın ~80%'i
- Kalem genişliği: 8-12 piksel (tipe göre değişir)
- Padding: Her yönden minimum 4px

### Renk Paleti
```
Gövde Renkleri:
- Krem/Bej: #F5F0E6, #EDE8DC
- Beyaz: #FFFFFF, #FAFAFA
- Açık gri: #E8E8E8, #D9D9D9
- Sarı (highlighter): #FFF176, #FFEE58
- Pembe: #FFCDD2, #F8BBD9

Uç Renkleri:
- Siyah grafit: #2D2D2D, #1A1A1A
- Gri grafit: #757575, #9E9E9E
- Metal: #B0BEC5, #78909C

Gölge:
- Soft shadow: rgba(0,0,0,0.08) - blur 4px
- Inner shadow: rgba(0,0,0,0.05) - blur 2px

Highlight:
- Top highlight: rgba(255,255,255,0.6)
- Edge highlight: rgba(255,255,255,0.3)
```

---

## Kalem Tipleri Detaylı Spec

### 1. Kurşun Kalem (Pencil)
```
Gövde: Altıgen prizma (hexagonal)
Renk: Bej/krem gradient (#F5E6D3 → #E8D4BE)
Uç: Konik, ahşap görünüm + siyah grafit
Detay: 
- Ahşap doku çizgileri (çok subtle)
- Üst kısımda metal halka + pembe silgi
- Grafit ucu parlak highlight

Gölge efekti:
- Sol alt tarafa soft shadow
- Sağ üst kenarda highlight
```

### 2. Sert Kalem (Hard Pencil)
```
Gövde: Kurşun kalemle aynı form
Renk: Daha açık, grimsi ton (#E8E4E0 → #D4D0CC)
Uç: Daha açık gri grafit (#9E9E9E)
Detay:
- Daha mat görünüm
- Subtle texture
```

### 3. Tükenmez Kalem (Ballpoint Pen)
```
Gövde: Silindirik, ince
Renk: Beyaz/krem (#FFFFFF → #F5F5F5)
Uç: Metal klips + ince siyah uç
Detay:
- Üst kısımda tıklama butonu
- Metal klips (gümüş gradient)
- Gövdede subtle vertical highlight
```

### 4. Dolma Kalem (Fountain Pen)
```
Gövde: Elegant, hafif konik
Renk: Koyu lacivert veya siyah (#1A237E → #0D1642)
Uç: Altın/gümüş nib (metal uç)
Detay:
- Nib detayı (split tip görünümü)
- Metal bant (gold: #FFD700)
- Glossy finish (parlak yansıma)
```

### 5. Jel Kalem (Gel Pen)
```
Gövde: Şeffaf/yarı saydam
Renk: Hafif tinted transparency
Uç: Renkli mürekkep görünür
Detay:
- İç kısımda mürekkep deposu görünümü
- Rubber grip bölgesi
- Yuvarlak, smooth uç
```

### 6. Kesik Çizgi Kalem (Dashed Pen)
```
Gövde: Standart kalem formu
Renk: Beyaz/açık gri
Uç: Normal, ama gövdede dash pattern indicator
Detay:
- Gövde üzerinde "---" sembolü veya pattern
- Uç kısmı normal
```

### 7. Fosforlu Kalem (Highlighter)
```
Gövde: Geniş, dikdörtgenimsi
Renk: Sarı gradient (#FFF59D → #FFEE58)
Uç: Kesik uç (chisel tip), geniş
Detay:
- Yarı saydam görünüm
- Kapak detayı (üst kısım)
- Soft glow efekti
```

### 8. Fırça Kalem (Brush Pen)
```
Gövde: İnce, elegant
Renk: Siyah veya koyu gri (#424242)
Uç: Fırça kılları (bristle tip)
Detay:
- Kıl ucu detayı (birkaç çizgi)
- Tapered shape (incelen form)
- Mat finish
```

### 9. Keçeli Kalem (Marker)
```
Gövde: Kalın, silindirik
Renk: Gövde rengi = mürekkep rengi
Uç: Düz, bullet tip
Detay:
- Kapak çizgisi
- Opak, mat görünüm
- Bold presence
```

### 10. Neon Fosforlu (Neon Highlighter)
```
Gövde: Highlighter benzeri form
Renk: Parlak neon (#76FF03, #00E5FF, #FF4081)
Uç: Chisel tip
Detay:
- GLOW efekti (outer glow)
- Daha yoğun renk
- Parlak, electric görünüm
```

---

## CustomPainter Implementasyon Notları

### Temel Yapı
```dart
class PenIconPainter extends CustomPainter {
  // 1. Ana gövde path'i çiz
  // 2. Gradient uygula
  // 3. Gölge ekle (drawShadow)
  // 4. Highlight ekle
  // 5. Detayları çiz (uç, klips, vb.)
}
```

### Gradient Kullanımı
```dart
final gradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [lighterColor, darkerColor],
);

final paint = Paint()
  ..shader = gradient.createShader(rect);
```

### Soft Shadow
```dart
// Shadow için ayrı path çiz, blur uygula
canvas.drawShadow(
  path.shift(Offset(2, 2)), // offset
  Colors.black.withOpacity(0.1),
  4.0, // elevation
  false,
);
```

### 3D Highlight
```dart
// Üst kenar highlight
final highlightPaint = Paint()
  ..color = Colors.white.withOpacity(0.4)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5;

canvas.drawPath(topEdgePath, highlightPaint);
```

---

## Render Order (Z-Index)

1. Drop shadow (en altta)
2. Main body fill
3. Body gradient/texture
4. Tip/nib
5. Details (clips, bands, buttons)
6. Highlights (en üstte)

---

## Test Kriterleri

- [ ] 56x56 canvas'ta net görünüm
- [ ] 32x32'ye scale edildiğinde hala tanınabilir
- [ ] Açık ve koyu tema'da iyi görünüm
- [ ] Seçili state'te belirgin (subtle highlight)
- [ ] Tüm kalemler tutarlı stil
- [ ] Performans: paint() <1ms

---

## Referans Görsel Analizi

Görseldeki sıralama (soldan sağa):
1. Siyah uçlu kurşun kalem
2. Gri uçlu sert kalem  
3. Dolma kalem (metal nib)
4. Beyaz tükenmez kalem
5. Bej/ten rengi jel kalem
6. Pembemsi fırça/marker
7. Gökkuşağı uçlu (multi-color)
8. Sarı fosforlu kalem
9. Sarı marker/highlighter

Canvas'taki çizgiler her kalemin stroke stilini gösteriyor:
- İnce siyah → Kurşun kalem
- İnce gri → Sert kalem
- İnce siyah (net) → Tükenmez
- Cyan düz çizgi → Jel kalem
- Pembe kesikli → Dashed pen
- Kalın peach → Brush/marker
- Kahverengi → Marker
- Neon yeşil → Neon highlighter

---

*Bu spec'e göre CustomPainter'lar implemente edilecek.*
