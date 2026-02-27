# TEMPLATE ENHANCEMENT — STEP 2: Yapısal Template Painter'ları

## BAĞLAM
Step 1'de drawing_core'a 12 yeni yapısal TemplatePattern eklendi:
dailyPlanner, weeklyPlanner, monthlyPlanner, bulletJournal, gratitudeJournal,
todoList, checklist, storyboard, wireframe, meetingNotes, readingLog, vocabularyList

Şimdi bu pattern'ların drawing_ui'da görsel çizimlerini yapacağız.

## BRANCH
```bash
git checkout main
git pull origin main
git checkout -b feature/template-painters
```

---

## ⚠️ KRİTİK KURALLAR — HER SATIRDA UYGULA

### RENK KURALI
- HARD CODED RENK KULLANMA. Hiçbir yerde `Color(0xFF...)`, `Colors.grey`, `Colors.blue` gibi sabit renk OLMASIN.
- Tüm renkler `lineColor` ve `backgroundColor` parametrelerinden gelsin.
- Vurgu çizgiler: `lineColor.withValues(alpha: 0.3)` veya `lineColor.withValues(alpha: 0.7)` gibi alpha varyasyonları kullan.
- Kalın çizgiler: `lineColor` aynen, ince çizgiler: `lineColor.withValues(alpha: 0.5)`.
- Header arka planı: `lineColor.withValues(alpha: 0.05)` gibi çok hafif ton.
- Metin rengi: ÇIZME — template'lardaki "Saat", "Hedefler" gibi label'ları ince çizgi ile işaretle, Text widget kullanma (bu CustomPainter).

### RESPONSIVE / MOBİL UYUMLULUK KURALI
- SABİT PİKSEL KULLANMA. Her ölçü `size.width` veya `size.height` yüzdesi olsun.
- Margin: `size.width * 0.05` (sabit 20px değil)
- Header yüksekliği: `size.height * 0.08` (sabit 60px değil)
- Sütun genişliği: `size.width * 0.65` (sabit 400px değil)
- Font size yok — TextPainter KULLANMA, sadece geometrik şekiller çiz.
- Checkbox boyutu: `min(size.width, size.height) * 0.02` gibi orantılı

### GENEL KURALLAR
- Mevcut pattern'ların (_drawCornell, _drawMusic vs.) koduna DOKUNMA
- Yeni case'ler switch'e SONA ekle
- Her _draw metodu max 80 satır — uzarsa helper'a böl
- `_spacingPx` getter'ını mevcut olarak kullan (mm→px dönüşüm)
- `extraData` map'ten config oku, yoksa makul default kullan
- `_linePaint` getter'ını kullan (lineColor + lineWidth ayarlı)

---

## GÖREV 1: TemplatePatternPainter'a Yeni Case'ler Ekle

**Dosya:** `packages/drawing_ui/lib/src/painters/template_pattern_painter.dart`

Mevcut `paint()` metodundaki switch'e yeni case'ler ekle. Mevcut case'lere DOKUNMA.

```dart
  @override
  void paint(Canvas canvas, Size size) {
    // Arka plan (MEVCUT — DOKUNMA)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    switch (pattern) {
      // === MEVCUT CASE'LER — DOKUNMA ===
      case TemplatePattern.blank:
        break;
      case TemplatePattern.thinLines:
      case TemplatePattern.mediumLines:
      case TemplatePattern.thickLines:
        _drawLines(canvas, size);
        break;
      // ... diğer mevcut case'ler ...

      // === YENİ CASE'LER — EKLE ===
      case TemplatePattern.dailyPlanner:
        _drawDailyPlanner(canvas, size);
        break;
      case TemplatePattern.weeklyPlanner:
        _drawWeeklyPlanner(canvas, size);
        break;
      case TemplatePattern.monthlyPlanner:
        _drawMonthlyPlanner(canvas, size);
        break;
      case TemplatePattern.bulletJournal:
        _drawBulletJournal(canvas, size);
        break;
      case TemplatePattern.gratitudeJournal:
        _drawGratitudeJournal(canvas, size);
        break;
      case TemplatePattern.todoList:
        _drawTodoList(canvas, size);
        break;
      case TemplatePattern.checklist:
        _drawChecklist(canvas, size);
        break;
      case TemplatePattern.storyboard:
        _drawStoryboard(canvas, size);
        break;
      case TemplatePattern.wireframe:
        _drawWireframe(canvas, size);
        break;
      case TemplatePattern.meetingNotes:
        _drawMeetingNotes(canvas, size);
        break;
      case TemplatePattern.readingLog:
        _drawReadingLog(canvas, size);
        break;
      case TemplatePattern.vocabularyList:
        _drawVocabularyList(canvas, size);
        break;
    }
  }
```

---

## GÖREV 2: Her Pattern İçin _draw Metodu Yaz

Aşağıdaki 12 metodu TemplatePatternPainter sınıfına ekle.
Her metotta RENK ve BOYUT kurallarına dikkat et.

### Ortak yardımcı (varsa ekle, yoksa oluştur):

```dart
  /// Yatay ayırıcı çizgi çizer (kalın)
  void _drawDivider(Canvas canvas, double y, double startX, double endX, Paint paint) {
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      paint..strokeWidth = lineWidth * 2,
    );
  }

  /// Checkbox çizer (boş kare)
  void _drawCheckbox(Canvas canvas, Offset topLeft, double size, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size),
      Radius.circular(size * 0.15),
    );
    canvas.drawRRect(rect, paint..style = PaintingStyle.stroke..strokeWidth = lineWidth);
  }

  /// Bölge başlık çizgisi (ince yatay çizgi + üstünde boşluk)
  void _drawSectionHeader(Canvas canvas, double y, double startX, double endX, Paint paint) {
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      paint..strokeWidth = lineWidth * 1.5,
    );
  }
```

---

### 1. _drawDailyPlanner

```
Layout:
┌─────────────────────────────────────┐
│          Header (h: %8)             │  ← ince çizgi ile ayrılmış üst bölge
├──────────────────┬──────────────────┤
│                  │                  │
│  Zaman Bloğu     │  Sağ Panel      │  ← %62 / %38 dikey bölünme
│  (saatlik        │  (üst yarı:     │
│   çizgiler)      │   hedef satırları│
│                  │   alt yarı:     │
│                  │   çizgili notlar)│
│                  │                  │
└──────────────────┴──────────────────┘
```

```dart
  void _drawDailyPlanner(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.08;
    final dividerX = size.width * 0.62;

    // Header ayırıcı
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    // Dikey bölme çizgisi
    canvas.drawLine(
      Offset(dividerX, headerH),
      Offset(dividerX, size.height - margin),
      paint..strokeWidth = lineWidth * 1.5,
    );

    // Sol: Saatlik çizgiler
    final startHour = (extraData?['startHour'] as int?) ?? 6;
    final endHour = (extraData?['endHour'] as int?) ?? 22;
    final totalHours = endHour - startHour;
    final availableH = size.height - headerH - margin;
    final hourH = availableH / totalHours;
    
    paint.strokeWidth = lineWidth;
    for (int i = 0; i <= totalHours; i++) {
      final y = headerH + (i * hourH);
      // Ana saat çizgisi
      canvas.drawLine(
        Offset(margin, y),
        Offset(dividerX - margin, y),
        paint,
      );
      // Yarım saat çizgisi (daha kısa, daha soluk)
      if (i < totalHours) {
        final halfY = y + hourH * 0.5;
        canvas.drawLine(
          Offset(margin + (dividerX * 0.15), halfY),
          Offset(dividerX - margin, halfY),
          Paint()
            ..color = lineColor.withValues(alpha: 0.3)
            ..strokeWidth = lineWidth * 0.5,
        );
      }
    }

    // Sağ üst: Hedef checkbox'ları (panel yüksekliğinin %40'ı)
    final rightStart = dividerX + margin;
    final rightEnd = size.width - margin;
    final goalSectionH = availableH * 0.4;
    final goalDividerY = headerH + goalSectionH;
    
    _drawDivider(canvas, goalDividerY, rightStart, rightEnd, paint);
    
    final checkboxSize = min(size.width, size.height) * 0.025;
    final goalLineH = goalSectionH / 6;
    for (int i = 0; i < 5; i++) {
      final y = headerH + margin + (i * goalLineH);
      _drawCheckbox(canvas, Offset(rightStart, y + goalLineH * 0.2), checkboxSize, Paint()..color = lineColor);
      canvas.drawLine(
        Offset(rightStart + checkboxSize + margin, y + goalLineH * 0.5 + checkboxSize * 0.5),
        Offset(rightEnd, y + goalLineH * 0.5 + checkboxSize * 0.5),
        Paint()..color = lineColor.withValues(alpha: 0.4)..strokeWidth = lineWidth * 0.5,
      );
    }

    // Sağ alt: Not çizgileri
    paint.strokeWidth = lineWidth;
    paint.color = lineColor.withValues(alpha: 0.5);
    for (double y = goalDividerY + _spacingPx; y < size.height - margin; y += _spacingPx) {
      canvas.drawLine(Offset(rightStart, y), Offset(rightEnd, y), paint);
    }
  }
```

⚠️ Dikkat: Hiçbir yerde sabit piksel yok, her şey `size.width * X` veya `size.height * X` oranında. Renklerde `lineColor` ve alpha varyasyonları kullanıldı.

---

### 2. _drawWeeklyPlanner

```
Layout:
┌─────────────────────────────────────┐
│          Header (h: %6)             │
├─────┬─────┬─────┬─────┬─────┬──────┤
│ Pzt │ Sal │ Çar │ Per │ Cum │ C.Si │  ← 7 gün (son sütun %12 daha geniş)
│     │     │     │     │     │ Paz  │
│     │     │     │     │     │      │
│ çiz │ çiz │ çiz │ çiz │ çiz │ çiz  │  ← her sütunda yatay çizgiler
│ gil │ gil │ gil │ gil │ gil │ gil  │
│ er  │ er  │ er  │ er  │ er  │ er   │
├─────┴─────┴─────┴─────┴─────┴──────┤
│          Notlar (h: %15)            │  ← alt bölge, çizgili
└─────────────────────────────────────┘
```

```dart
  void _drawWeeklyPlanner(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.06;
    final footerH = size.height * 0.15;
    final bodyH = size.height - headerH - footerH;

    // Header ayırıcı
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    // Footer ayırıcı (notlar bölümü)
    _drawDivider(canvas, size.height - footerH, margin, size.width - margin, paint);

    // 7 gün sütunları
    final dayCount = 7;
    final dayW = (size.width - margin * 2) / dayCount;

    for (int i = 1; i < dayCount; i++) {
      final x = margin + (i * dayW);
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - footerH),
        paint..strokeWidth = lineWidth,
      );
    }

    // Her sütunda yatay çizgiler
    paint.color = lineColor.withValues(alpha: 0.4);
    paint.strokeWidth = lineWidth * 0.5;
    for (double y = headerH + _spacingPx; y < size.height - footerH; y += _spacingPx) {
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        paint,
      );
    }

    // Footer: not çizgileri
    paint.color = lineColor.withValues(alpha: 0.5);
    for (double y = size.height - footerH + _spacingPx; y < size.height - margin; y += _spacingPx) {
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        paint,
      );
    }
  }
```

---

### 3. _drawMonthlyPlanner

```
Layout:
┌─────────────────────────────────────┐
│          Header (h: %8)             │
├─────┬─────┬─────┬─────┬─────┬──┬──┤
│     │     │     │     │     │  │  │  ← 7 sütun
├─────┼─────┼─────┼─────┼─────┼──┼──┤
│     │     │     │     │     │  │  │  ← 6 satır (takvim grid)
├─────┼─────┼─────┼─────┼─────┼──┼──┤
│     │     │     │     │     │  │  │
├─────┴─────┴─────┴─────┴─────┴──┴──┤
│          Notlar (h: %12)            │
└─────────────────────────────────────┘
```

```dart
  void _drawMonthlyPlanner(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.08;
    final footerH = size.height * 0.12;
    final gridH = size.height - headerH - footerH;
    final cols = (extraData?['gridCols'] as int?) ?? 7;
    final rows = (extraData?['gridRows'] as int?) ?? 6;

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);
    // Footer
    _drawDivider(canvas, size.height - footerH, margin, size.width - margin, paint);

    final cellW = (size.width - margin * 2) / cols;
    final cellH = gridH / rows;

    // Dikey çizgiler
    for (int i = 0; i <= cols; i++) {
      final x = margin + (i * cellW);
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - footerH),
        paint..strokeWidth = lineWidth,
      );
    }

    // Yatay çizgiler
    for (int i = 0; i <= rows; i++) {
      final y = headerH + (i * cellH);
      canvas.drawLine(
        Offset(margin, y),
        Offset(size.width - margin, y),
        paint..strokeWidth = lineWidth,
      );
    }

    // Footer: not çizgileri
    paint.color = lineColor.withValues(alpha: 0.5);
    paint.strokeWidth = lineWidth * 0.5;
    for (double y = size.height - footerH + _spacingPx; y < size.height - margin; y += _spacingPx) {
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }
```

---

### 4. _drawBulletJournal

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %6)                     │
├─────────────────────────────────────┤
│  • ──────────────────────────────── │  ← bullet noktaları + çizgiler
│  • ──────────────────────────────── │
│  ○ ──────────────────────────────── │
│  • ──────────────────────────────── │
│  ...                                │
│  (sol margin'da bullet noktaları,   │
│   sağda çizgili alan)              │
└─────────────────────────────────────┘
Dot grid overlay (ince, arka planda)
```

```dart
  void _drawBulletJournal(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.06;
    final bulletMargin = size.width * 0.08;

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    // Sol kenar çizgisi (bullet alanı ayırıcı)
    canvas.drawLine(
      Offset(bulletMargin, headerH),
      Offset(bulletMargin, size.height - margin),
      Paint()..color = lineColor.withValues(alpha: 0.3)..strokeWidth = lineWidth,
    );

    // Yatay çizgiler (bullet satırları)
    paint.color = lineColor.withValues(alpha: 0.4);
    paint.strokeWidth = lineWidth * 0.5;
    int lineIndex = 0;
    for (double y = headerH + _spacingPx; y < size.height - margin; y += _spacingPx) {
      // Çizgi
      canvas.drawLine(Offset(bulletMargin + margin * 0.5, y), Offset(size.width - margin, y), paint);

      // Bullet noktası (her satırda küçük nokta)
      final bulletY = y - _spacingPx * 0.5;
      if (bulletY > headerH) {
        final bulletR = min(size.width, size.height) * 0.005;
        canvas.drawCircle(
          Offset(bulletMargin * 0.55, bulletY),
          bulletR,
          Paint()..color = lineColor.withValues(alpha: 0.6)..style = PaintingStyle.fill,
        );
      }
      lineIndex++;
    }

    // Opsiyonel: arka plan dot grid (çok ince)
    if (extraData?['dotGrid'] == true) {
      final dotPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      final dotSpacing = _spacingPx * 0.5;
      final dotR = lineWidth * 0.5;
      for (double x = bulletMargin + dotSpacing; x < size.width - margin; x += dotSpacing) {
        for (double y = headerH + dotSpacing; y < size.height - margin; y += dotSpacing) {
          canvas.drawCircle(Offset(x, y), dotR, dotPaint);
        }
      }
    }
  }
```

---

### 5. _drawGratitudeJournal

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %8)  [tarih alanı]     │
├─────────────────────────────────────┤
│  Bölge 1 (h: %25) — 3 prompt satırı│
│  ── ─── ─── ─── ─── ─── ─── ─── ──│
│  ── ─── ─── ─── ─── ─── ─── ─── ──│
│  ── ─── ─── ─── ─── ─── ─── ─── ──│
├─────────────────────────────────────┤
│  Bölge 2 (h: %35) — günlük yazı    │
│  çizgili alan                       │
├─────────────────────────────────────┤
│  Bölge 3 (h: %25) — mood/duygu     │
│  5 yuvarlak (mood scale)            │
└─────────────────────────────────────┘
```

```dart
  void _drawGratitudeJournal(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.05;
    final headerH = size.height * 0.08;
    final section1H = size.height * 0.25;
    final section2H = size.height * 0.35;
    // section3 = kalan alan

    final section1Y = headerH;
    final section2Y = section1Y + section1H;
    final section3Y = section2Y + section2H;

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    // Bölüm ayırıcılar
    _drawDivider(canvas, section2Y, margin, size.width - margin, paint);
    _drawDivider(canvas, section3Y, margin, size.width - margin, paint);

    // Bölüm 1: Prompt satırları (3 adet, aralıklı)
    final promptCount = (extraData?['promptCount'] as int?) ?? 3;
    final promptLineH = section1H / (promptCount + 1);
    paint.color = lineColor.withValues(alpha: 0.4);
    paint.strokeWidth = lineWidth * 0.5;
    for (int i = 1; i <= promptCount; i++) {
      final y = section1Y + (i * promptLineH);
      // Numaralama noktası
      final dotR = min(size.width, size.height) * 0.008;
      canvas.drawCircle(
        Offset(margin + dotR, y),
        dotR,
        Paint()..color = lineColor.withValues(alpha: 0.5)..style = PaintingStyle.fill,
      );
      // Çizgi
      canvas.drawLine(
        Offset(margin + dotR * 4, y),
        Offset(size.width - margin, y),
        paint,
      );
    }

    // Bölüm 2: Serbest yazı çizgileri
    for (double y = section2Y + _spacingPx; y < section3Y - margin * 0.5; y += _spacingPx) {
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }

    // Bölüm 3: Mood scale (5 daire)
    if (extraData?['showMoodScale'] != false) {
      final moodY = section3Y + (size.height - section3Y) * 0.4;
      final moodCount = 5;
      final moodSpacing = (size.width - margin * 4) / (moodCount - 1);
      final moodR = min(size.width, size.height) * 0.025;
      final moodPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth;
      for (int i = 0; i < moodCount; i++) {
        final x = margin * 2 + (i * moodSpacing);
        canvas.drawCircle(Offset(x, moodY), moodR, moodPaint);
      }
    }

    // Bölüm 3 alt: not çizgileri
    for (double y = section3Y + (size.height - section3Y) * 0.55; y < size.height - margin; y += _spacingPx) {
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }
```

---

### 6. _drawTodoList

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %7)                     │
├──┬──┬───────────────────────────────┤
│P │☐│ ─────────────────────────────  │  ← P=öncelik, ☐=checkbox, çizgi
│P │☐│ ─────────────────────────────  │
│P │☐│ ─────────────────────────────  │
│  │  │                               │
│  │  │  ... (tekrar eden satırlar)   │
└──┴──┴───────────────────────────────┘
Sol: öncelik sütunu (%6), checkbox sütunu (%6), sağ: görev çizgisi
```

```dart
  void _drawTodoList(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.07;
    final priorityW = size.width * 0.06;
    final checkboxW = size.width * 0.06;
    final contentStart = margin + priorityW + checkboxW;
    final checkboxSize = min(size.width, size.height) * 0.022;
    final rowH = _spacingPx * 1.2;

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    // Dikey ayırıcı: öncelik | checkbox | içerik
    canvas.drawLine(
      Offset(margin + priorityW, headerH),
      Offset(margin + priorityW, size.height - margin),
      Paint()..color = lineColor.withValues(alpha: 0.3)..strokeWidth = lineWidth * 0.5,
    );
    canvas.drawLine(
      Offset(margin + priorityW + checkboxW, headerH),
      Offset(margin + priorityW + checkboxW, size.height - margin),
      Paint()..color = lineColor.withValues(alpha: 0.3)..strokeWidth = lineWidth * 0.5,
    );

    // Satırlar
    paint.color = lineColor.withValues(alpha: 0.3);
    paint.strokeWidth = lineWidth * 0.5;
    for (double y = headerH + rowH; y < size.height - margin; y += rowH) {
      // Yatay çizgi
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);

      // Checkbox
      final cbY = y - rowH * 0.5 - checkboxSize * 0.5;
      final cbX = margin + priorityW + (checkboxW - checkboxSize) * 0.5;
      _drawCheckbox(canvas, Offset(cbX, cbY), checkboxSize, Paint()..color = lineColor);
    }
  }
```

---

### 7. _drawChecklist

```
Layout (basit — todoList'ten daha sade):
┌─────────────────────────────────────┐
│  Header (h: %6)                     │
├─────────────────────────────────────┤
│ ☐  ──────────────────────────────── │
│ ☐  ──────────────────────────────── │
│ ☐  ──────────────────────────────── │
│ ...                                 │
└─────────────────────────────────────┘
```

```dart
  void _drawChecklist(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.05;
    final headerH = size.height * 0.06;
    final checkboxSize = min(size.width, size.height) * 0.02;
    final checkboxMargin = size.width * 0.08;
    final rowH = _spacingPx;

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    // Satırlar
    paint.color = lineColor.withValues(alpha: 0.4);
    paint.strokeWidth = lineWidth * 0.5;
    for (double y = headerH + rowH; y < size.height - margin; y += rowH) {
      // Checkbox
      final cbY = y - rowH * 0.5 - checkboxSize * 0.5;
      _drawCheckbox(canvas, Offset(margin, cbY), checkboxSize, Paint()..color = lineColor);

      // Çizgi
      canvas.drawLine(
        Offset(checkboxMargin, y),
        Offset(size.width - margin, y),
        paint,
      );
    }
  }
```

---

### 8. _drawStoryboard

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %5)                     │
├──────────────────┬──────────────────┤
│  ┌────────────┐  │  ┌────────────┐  │  ← 2 sütun, 3 satır = 6 frame
│  │  16:9      │  │  │  16:9      │  │
│  │  frame     │  │  │  frame     │  │
│  └────────────┘  │  └────────────┘  │
│  ─── ─── ───     │  ─── ─── ───     │  ← açıklama çizgileri
├──────────────────┼──────────────────┤
│  ┌────────────┐  │  ┌────────────┐  │
│  ...             │  ...             │
└──────────────────┴──────────────────┘
```

```dart
  void _drawStoryboard(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.05;
    final framesPerPage = (extraData?['framesPerPage'] as int?) ?? 6;
    final cols = 2;
    final rows = (framesPerPage / cols).ceil();

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    final cellW = (size.width - margin * 2) / cols;
    final cellH = (size.height - headerH - margin) / rows;
    final framePadding = cellW * 0.08;

    // Aspect ratio
    final aspectStr = (extraData?['aspectRatio'] as String?) ?? '16:9';
    final parts = aspectStr.split(':');
    final aspect = (double.tryParse(parts[0]) ?? 16) / (double.tryParse(parts[1]) ?? 9);

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cellX = margin + (col * cellW);
        final cellY = headerH + (row * cellH);

        // Frame boyutu hesapla (aspect ratio'ya göre)
        final frameW = cellW - framePadding * 2;
        var frameH = frameW / aspect;
        if (frameH > cellH * 0.6) frameH = cellH * 0.6;

        final frameX = cellX + framePadding;
        final frameY = cellY + framePadding;

        // Frame kutusu
        final frameRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(frameX, frameY, frameW, frameH),
          Radius.circular(frameW * 0.01),
        );
        canvas.drawRRect(frameRect, paint..style = PaintingStyle.stroke..strokeWidth = lineWidth);

        // Açıklama çizgileri (frame altında)
        final descY = frameY + frameH + framePadding * 0.8;
        final descLineSpacing = cellH * 0.08;
        final descPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..strokeWidth = lineWidth * 0.5;
        for (int i = 0; i < 2; i++) {
          final y = descY + (i * descLineSpacing);
          if (y < cellY + cellH - framePadding * 0.5) {
            canvas.drawLine(Offset(frameX, y), Offset(frameX + frameW, y), descPaint);
          }
        }
      }
    }
  }
```

---

### 9. _drawWireframe

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %5)                     │
├─────────────────────────────────────┤
│     ┌──────────┐                    │
│     │ ┌──────┐ │                    │  ← telefon outline
│     │ │ grid │ │                    │
│     │ │      │ │                    │
│     │ └──────┘ │                    │
│     └──────────┘                    │
│  (3 frame dikey, her biri telefon)  │
└─────────────────────────────────────┘
```

```dart
  void _drawWireframe(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.04;
    final headerH = size.height * 0.05;
    final deviceType = (extraData?['deviceType'] as String?) ?? 'mobile';
    final framesPerPage = (extraData?['framesPerPage'] as int?) ?? 3;

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);

    // Device aspect ratio
    final deviceAspect = deviceType == 'tablet' ? 4.0 / 3.0 : 9.0 / 19.5;

    final availableH = size.height - headerH - margin * 2;
    final frameH = availableH / framesPerPage - margin;
    final frameW = frameH * deviceAspect;
    final frameX = (size.width - frameW) * 0.5;

    for (int i = 0; i < framesPerPage; i++) {
      final frameY = headerH + margin + (i * (frameH + margin));

      // Device outline (rounded rect)
      final deviceRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(frameX, frameY, frameW, frameH),
        Radius.circular(frameW * 0.06),
      );
      canvas.drawRRect(deviceRect, paint..style = PaintingStyle.stroke..strokeWidth = lineWidth * 1.5);

      // İç grid (ince, opsiyonel)
      if (extraData?['showGrid'] == true) {
        final innerMargin = frameW * 0.05;
        final gridSpacing = frameW * 0.1;
        final gridPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.15)
          ..strokeWidth = lineWidth * 0.3;
        for (double x = frameX + innerMargin + gridSpacing; x < frameX + frameW - innerMargin; x += gridSpacing) {
          canvas.drawLine(Offset(x, frameY + innerMargin), Offset(x, frameY + frameH - innerMargin), gridPaint);
        }
        for (double y = frameY + innerMargin + gridSpacing; y < frameY + frameH - innerMargin; y += gridSpacing) {
          canvas.drawLine(Offset(frameX + innerMargin, y), Offset(frameX + frameW - innerMargin, y), gridPaint);
        }
      }

      // Status bar hint (üstte ince çizgi)
      final statusY = frameY + frameH * 0.04;
      canvas.drawLine(
        Offset(frameX + frameW * 0.1, statusY),
        Offset(frameX + frameW * 0.9, statusY),
        Paint()..color = lineColor.withValues(alpha: 0.2)..strokeWidth = lineWidth * 0.3,
      );
    }
  }
```

---

### 10. _drawMeetingNotes

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %8) — toplantı bilgisi │
├─────────────────────────────────────┤
│  Bölge 1 (h: %15) — katılımcılar   │
│  ── ── ── ── ── ── ── ── ── ── ──  │
├─────────────────────────────────────┤
│  Bölge 2 (h: %15) — gündem         │
│  ── ── ── ── ── ── ── ── ── ── ──  │
├─────────────────────────────────────┤
│  Bölge 3 (h: %35) — notlar         │
│  çizgili alan                       │
├─────────────────────────────────────┤
│  Bölge 4 (h: %20) — aksiyon items  │
│  ☐ ─── ☐ ─── ☐ ───                │
└─────────────────────────────────────┘
```

```dart
  void _drawMeetingNotes(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.05;
    final headerH = size.height * 0.08;
    final s1H = size.height * 0.15; // katılımcılar
    final s2H = size.height * 0.15; // gündem
    final s4H = size.height * 0.20; // aksiyon
    // s3 = kalan (notlar)

    final s1Y = headerH;
    final s2Y = s1Y + s1H;
    final s3Y = s2Y + s2H;
    final s4Y = size.height - s4H;

    // Bölüm ayırıcılar
    _drawDivider(canvas, s1Y, margin, size.width - margin, paint);
    _drawDivider(canvas, s2Y, margin, size.width - margin, paint);
    _drawDivider(canvas, s3Y, margin, size.width - margin, paint);
    _drawDivider(canvas, s4Y, margin, size.width - margin, paint);

    // Her bölümde çizgiler
    paint.color = lineColor.withValues(alpha: 0.4);
    paint.strokeWidth = lineWidth * 0.5;

    // Bölüm 1-2: kısa çizgiler
    for (final sectionY in [s1Y, s2Y]) {
      final sectionEnd = sectionY == s1Y ? s2Y : s3Y;
      for (double y = sectionY + _spacingPx; y < sectionEnd - margin * 0.3; y += _spacingPx) {
        canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
      }
    }

    // Bölüm 3: not çizgileri
    for (double y = s3Y + _spacingPx; y < s4Y - margin * 0.3; y += _spacingPx) {
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }

    // Bölüm 4: aksiyon checkbox'ları
    final checkboxSize = min(size.width, size.height) * 0.02;
    final actionRowH = _spacingPx * 1.2;
    for (double y = s4Y + actionRowH; y < size.height - margin; y += actionRowH) {
      _drawCheckbox(canvas, Offset(margin, y - checkboxSize * 0.5 - actionRowH * 0.2), checkboxSize, Paint()..color = lineColor);
      canvas.drawLine(
        Offset(margin + checkboxSize + margin * 0.5, y),
        Offset(size.width - margin, y),
        paint,
      );
    }
  }
```

---

### 11. _drawReadingLog

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %7)                     │
├────────┬──────────┬─────┬─────┬─────┤
│ Kitap  │  Yazar   │Sayfa│Puan │ Not │  ← 5 sütun header
├────────┼──────────┼─────┼─────┼─────┤
│        │          │     │     │     │  ← çizgili satırlar
│        │          │     │     │     │
└────────┴──────────┴─────┴─────┴─────┘
```

```dart
  void _drawReadingLog(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.07;
    final colHeaderH = size.height * 0.05;
    final colRatios = [0.25, 0.25, 0.15, 0.15, 0.20];

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);
    // Sütun header alt çizgisi
    _drawDivider(canvas, headerH + colHeaderH, margin, size.width - margin, paint);

    // Sütun ayırıcıları
    final usableW = size.width - margin * 2;
    double x = margin;
    for (int i = 0; i < colRatios.length - 1; i++) {
      x += usableW * colRatios[i];
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - margin),
        paint..strokeWidth = lineWidth,
      );
    }

    // Satır çizgileri
    paint.color = lineColor.withValues(alpha: 0.3);
    paint.strokeWidth = lineWidth * 0.5;
    final rowH = _spacingPx * 1.5;
    for (double y = headerH + colHeaderH + rowH; y < size.height - margin; y += rowH) {
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }
```

---

### 12. _drawVocabularyList

```
Layout:
┌─────────────────────────────────────┐
│  Header (h: %7)                     │
├──────────┬─────────────┬────────────┤
│  Sözcük  │   Anlam     │   Cümle    │  ← 3 sütun
├──────────┼─────────────┼────────────┤
│          │             │            │  ← çizgili satırlar
│          │             │            │
└──────────┴─────────────┴────────────┘
```

```dart
  void _drawVocabularyList(Canvas canvas, Size size) {
    final paint = _linePaint;
    final margin = size.width * 0.03;
    final headerH = size.height * 0.07;
    final colHeaderH = size.height * 0.05;
    final defaultRatios = [0.25, 0.35, 0.40];
    final colRatios = (extraData?['columnRatios'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList() ?? defaultRatios;

    // Header
    _drawDivider(canvas, headerH, margin, size.width - margin, paint);
    // Sütun header alt çizgisi
    _drawDivider(canvas, headerH + colHeaderH, margin, size.width - margin, paint);

    // Sütun ayırıcıları
    final usableW = size.width - margin * 2;
    double x = margin;
    for (int i = 0; i < colRatios.length - 1; i++) {
      x += usableW * colRatios[i];
      canvas.drawLine(
        Offset(x, headerH),
        Offset(x, size.height - margin),
        paint..strokeWidth = lineWidth,
      );
    }

    // Satır çizgileri
    paint.color = lineColor.withValues(alpha: 0.3);
    paint.strokeWidth = lineWidth * 0.5;
    for (double y = headerH + colHeaderH + _spacingPx; y < size.height - margin; y += _spacingPx) {
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), paint);
    }
  }
```

---

## GÖREV 3: Testleri Güncelle

**Dosya:** `packages/drawing_ui/test/painters/template_pattern_painter_test.dart`

Mevcut testlere dokunma, yeni testleri SONA ekle:

```dart
    // === YENİ YAPISAL PATTERN TESTLERİ ===

    group('structural patterns', () {
      final structuralPatterns = [
        TemplatePattern.dailyPlanner,
        TemplatePattern.weeklyPlanner,
        TemplatePattern.monthlyPlanner,
        TemplatePattern.bulletJournal,
        TemplatePattern.gratitudeJournal,
        TemplatePattern.todoList,
        TemplatePattern.checklist,
        TemplatePattern.storyboard,
        TemplatePattern.wireframe,
        TemplatePattern.meetingNotes,
        TemplatePattern.readingLog,
        TemplatePattern.vocabularyList,
      ];

      for (final pattern in structuralPatterns) {
        testWidgets('${pattern.name} renders without error', (tester) async {
          final painter = TemplatePatternPainter(
            pattern: pattern,
            spacingMm: pattern.defaultSpacingMm,
            lineWidth: pattern.defaultLineWidth,
            lineColor: const Color(0xFFCCCCCC),
            backgroundColor: const Color(0xFFFFFFFF),
            pageSize: const Size(595, 842), // A4
            extraData: null,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  size: const Size(595, 842),
                  painter: painter,
                ),
              ),
            ),
          );

          expect(find.byType(CustomPaint), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('daily planner renders on small screen (phone)', (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.dailyPlanner,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: const Color(0xFFCCCCCC),
          backgroundColor: const Color(0xFFFFFFFF),
          pageSize: const Size(375, 667), // iPhone SE
          extraData: {'startHour': 6, 'endHour': 22},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(375, 667),
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('storyboard renders with different aspect ratios', (tester) async {
        for (final aspect in ['16:9', '4:3']) {
          final painter = TemplatePatternPainter(
            pattern: TemplatePattern.storyboard,
            spacingMm: 0,
            lineWidth: 0.5,
            lineColor: const Color(0xFFCCCCCC),
            backgroundColor: const Color(0xFFFFFFFF),
            pageSize: const Size(595, 842),
            extraData: {'aspectRatio': aspect, 'framesPerPage': 6},
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CustomPaint(
                  size: const Size(595, 842),
                  painter: painter,
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('vocabulary list uses custom column ratios', (tester) async {
        final painter = TemplatePatternPainter(
          pattern: TemplatePattern.vocabularyList,
          spacingMm: 8,
          lineWidth: 0.5,
          lineColor: const Color(0xFFCCCCCC),
          backgroundColor: const Color(0xFFFFFFFF),
          pageSize: const Size(595, 842),
          extraData: {
            'columnRatios': [0.30, 0.30, 0.40],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(595, 842),
                painter: painter,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });
```

---

## GÖREV 4: Son Kontrol

```bash
cd packages/drawing_ui
flutter analyze
flutter test

cd ../../packages/drawing_core
flutter analyze
flutter test

cd ../../example_app
flutter analyze
```

Hata yoksa İlyas'a bildir, commit için onay bekle.

**Commit mesajı:**
```
feat(ui): add 12 structural template painters

- dailyPlanner, weeklyPlanner, monthlyPlanner
- bulletJournal, gratitudeJournal
- todoList, checklist
- storyboard, wireframe
- meetingNotes, readingLog, vocabularyList
- All responsive (no fixed pixels)
- All theme-aware (no hard-coded colors)
- Tests for all patterns including mobile sizes
```

---

## BU ADIMDA YAPILMAYACAKLAR
- Template picker UI (Step 3)
- Supabase entegrasyonu (Step 4)
- Kapak görselleri (Step 5)
- Mevcut painter'larda değişiklik
