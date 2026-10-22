# Phase 4E-2: Premium Pen Icons - REWRITE

> **SORUN:** Mevcut kalem ikonları oyuncak gibi görünüyor.
> **ÇÖZÜM:** Profesyonel tekniklerle yeniden yaz.

---

## Kritik Değişiklikler

### 1. Soft Shadow (MaskFilter.blur)
```dart
// ESKİ - sert gölge
canvas.drawShadow(path, Colors.black, 4.0, false);

// YENİ - soft gölge
final shadowPaint = Paint()
  ..color = Colors.black.withOpacity(0.18)
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

canvas.save();
canvas.translate(2.5, 3.0); // sağ-alt offset (ışık sol üstten)
canvas.drawPath(bodyPath, shadowPaint);
canvas.restore();
```

### 2. Multi-Stop Gradient (4-5 renk)
```dart
// ESKİ - 2 renk, düz
LinearGradient(colors: [light, dark])

// YENİ - 4 renk, gerçekçi silindir
LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    baseColor.withOpacity(0.6),  // highlight edge
    baseColor.withOpacity(0.9),  // light mid
    baseColor,                    // core
    baseColor.withOpacity(0.7),  // shadow edge + reflected
  ],
  stops: [0.0, 0.25, 0.6, 1.0],  // asimetrik - highlight'a yakın
)
```

### 3. Metal Gradient (reflected light dahil)
```dart
LinearGradient(
  colors: [
    Color(0xFFE0E0E0),  // bright highlight
    Color(0xFFB8B8B8),  // light metal
    Color(0xFF808080),  // shadow
    Color(0xFFA0A0A0),  // REFLECTED LIGHT - kritik!
  ],
  stops: [0.0, 0.3, 0.75, 1.0],
)
```

### 4. Strong Highlight (beyaz çizgi)
```dart
final highlightPaint = Paint()
  ..color = Colors.white.withOpacity(0.5)  // daha güçlü
  ..strokeWidth = 2.0  // daha kalın
  ..strokeCap = StrokeCap.round
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
```

---

## Cursor Talimatı

```
📋 GÖREV: Premium Pen Icons - Yeniden Yaz (Phase 4E-2 FIX)

Mevcut kalem painter'larını SİL ve aşağıdaki profesyonel versiyonlarla değiştir.

⚠️ KRİTİK KURALLAR:
- Tüm gölgeler MaskFilter.blur ile (drawShadow KULLANMA)
- Gradient'ler minimum 4 renk
- Işık kaynağı HEP sol üst (highlight sol, shadow sağ)
- Metal parçalarda reflected light olmalı
- Highlight beyaz, opacity 0.4-0.6, blur 0.5-1.0

---

DOSYA: packages/drawing_ui/lib/src/painters/pen_icons/pencil_icon_painter.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

class PencilIconPainter extends PenIconPainter {
  const PencilIconPainter({
    super.penColor = const Color(0xFF2D2D2D),
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    
    // Kalem gövdesi - 45° açılı, 1:7 oran
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.18, height: h * 0.55),
      const Radius.circular(1.5),
    ));
    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6); // 30°
    canvas.translate(-w / 2, -h / 2);
    
    // Soft shadow with blur
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    final shadowPath = Path();
    // Tüm kalem silüeti için shadow
    shadowPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.45), width: w * 0.18, height: h * 0.55),
      const Radius.circular(1.5),
    ));
    // Uç
    shadowPath.moveTo(w * 0.41, h * 0.72);
    shadowPath.lineTo(w * 0.5, h * 0.88);
    shadowPath.lineTo(w * 0.59, h * 0.72);
    shadowPath.close();
    
    canvas.translate(2.5, 3);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.45),
      width: w * 0.18,
      height: h * 0.55,
    );
    
    // 4-color gradient for cylindrical wood body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFF3E0),  // highlight edge (cream)
        Color(0xFFFFE0B2),  // light wood
        Color(0xFFFFCC80),  // core yellow
        Color(0xFFE6A84C),  // shadow + warm reflected
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(bodyRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
      Paint()..shader = bodyGradient,
    );
    
    // Subtle wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0xFFDDBB88).withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    for (var i = -1; i <= 1; i++) {
      final x = w * 0.5 + i * (w * 0.04);
      canvas.drawLine(
        Offset(x, h * 0.2),
        Offset(x, h * 0.65),
        grainPaint,
      );
    }
    
    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    // Sharpened wood cone
    final conePath = Path();
    conePath.moveTo(w * 0.41, h * 0.72);
    conePath.lineTo(w * 0.5, h * 0.88);
    conePath.lineTo(w * 0.59, h * 0.72);
    conePath.close();
    
    final coneGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8D4B8),  // light wood
        Color(0xFFD4A574),  // mid
        Color(0xFFB8865C),  // shadow
      ],
    ).createShader(conePath.getBounds());
    
    canvas.drawPath(conePath, Paint()..shader = coneGradient);
    
    // Graphite core - dark with slight sheen
    final graphitePath = Path();
    graphitePath.moveTo(w * 0.47, h * 0.82);
    graphitePath.lineTo(w * 0.5, h * 0.88);
    graphitePath.lineTo(w * 0.53, h * 0.82);
    graphitePath.close();
    
    final graphiteGradient = LinearGradient(
      colors: [
        penColor.withOpacity(0.8),
        penColor,
        penColor.withOpacity(0.9),
      ],
    ).createShader(graphitePath.getBounds());
    
    canvas.drawPath(graphitePath, Paint()..shader = graphiteGradient);
    
    canvas.restore();
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    // Metal ferrule with reflected light
    final ferruleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.14),
      width: w * 0.19,
      height: h * 0.06,
    );
    
    final ferruleGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD8D8D8),  // highlight
        Color(0xFFB0B0B0),  // light metal
        Color(0xFF787878),  // shadow
        Color(0xFF989898),  // reflected light!
      ],
      stops: const [0.0, 0.3, 0.75, 1.0],
    ).createShader(ferruleRect);
    
    canvas.drawRect(ferruleRect, Paint()..shader = ferruleGradient);
    
    // Ferrule ridge lines
    final ridgePaint = Paint()
      ..color = const Color(0xFF606060)
      ..strokeWidth = 0.4;
    
    for (var i = 0; i < 4; i++) {
      final x = ferruleRect.left + 2 + i * 3.0;
      canvas.drawLine(
        Offset(x, ferruleRect.top + 1),
        Offset(x, ferruleRect.bottom - 1),
        ridgePaint,
      );
    }
    
    // Pink eraser with gradient
    final eraserRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.07),
      width: w * 0.16,
      height: h * 0.08,
    );
    
    final eraserGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFCDD2),  // light pink
        Color(0xFFEF9A9A),  // pink
        Color(0xFFE57373),  // dark pink
        Color(0xFFEF9A9A),  // reflected
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(eraserRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(eraserRect, const Radius.circular(2)),
      Paint()..shader = eraserGradient,
    );
    
    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    // Strong white highlight on body left edge
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    
    canvas.drawLine(
      Offset(w * 0.42, h * 0.2),
      Offset(w * 0.42, h * 0.68),
      highlightPaint,
    );
    
    // Small highlight on eraser
    canvas.drawLine(
      Offset(w * 0.44, h * 0.04),
      Offset(w * 0.44, h * 0.09),
      highlightPaint..strokeWidth = 1.2,
    );
    
    canvas.restore();
  }
}

---

DOSYA: packages/drawing_ui/lib/src/painters/pen_icons/ballpoint_icon_painter.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

class BallpointIconPainter extends PenIconPainter {
  const BallpointIconPainter({
    super.penColor = const Color(0xFF1565C0),
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.width * 0.5, rect.height * 0.42),
        width: rect.width * 0.14,
        height: rect.height * 0.6,
      ),
      const Radius.circular(3),
    ));
    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    final shadowPath = Path();
    shadowPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.42), width: w * 0.14, height: h * 0.6),
      const Radius.circular(3),
    ));
    // Tip
    shadowPath.addPath(_createTipPath(w, h), Offset.zero);
    
    canvas.translate(3, 3.5);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  Path _createTipPath(double w, double h) {
    final path = Path();
    path.moveTo(w * 0.43, h * 0.72);
    path.quadraticBezierTo(w * 0.5, h * 0.9, w * 0.57, h * 0.72);
    path.close();
    return path;
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.42),
      width: w * 0.14,
      height: h * 0.6,
    );
    
    // Glossy white/cream plastic body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFFFFFFF),  // bright highlight
        Color(0xFFF8F8F8),  // white
        Color(0xFFEEEEEE),  // light gray
        Color(0xFFE0E0E0),  // shadow
        Color(0xFFEAEAEA),  // reflected
      ],
      stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
    ).createShader(bodyRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(3)),
      Paint()..shader = bodyGradient,
    );
    
    // Grip section (rubber texture)
    final gripRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.58),
      width: w * 0.15,
      height: h * 0.12,
    );
    
    final gripGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD0D0D0),
        Color(0xFFB8B8B8),
        Color(0xFF909090),
        Color(0xFFA8A8A8),
      ],
    ).createShader(gripRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(gripRect, const Radius.circular(2)),
      Paint()..shader = gripGradient,
    );
    
    // Grip texture lines
    final gripLinePaint = Paint()
      ..color = const Color(0xFF808080).withOpacity(0.4)
      ..strokeWidth = 0.5;
    
    for (var i = 0; i < 5; i++) {
      final y = gripRect.top + 2 + i * 2.5;
      canvas.drawLine(
        Offset(gripRect.left + 1, y),
        Offset(gripRect.right - 1, y),
        gripLinePaint,
      );
    }
    
    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    // Metal cone tip
    final tipPath = _createTipPath(w, h);
    
    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFD0D0D0),
        Color(0xFFA8A8A8),
        Color(0xFF707070),
        Color(0xFF909090),
      ],
    ).createShader(tipPath.getBounds());
    
    canvas.drawPath(tipPath, Paint()..shader = tipGradient);
    
    // Ball point
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.87),
      1.5,
      Paint()..color = penColor,
    );
    
    canvas.restore();
  }

  @override
  void paintDetails(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    // Click button on top
    final buttonRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.08),
      width: w * 0.08,
      height: h * 0.06,
    );
    
    final buttonGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        penColor.withOpacity(0.9),
        penColor,
        penColor.withOpacity(0.7),
      ],
    ).createShader(buttonRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(1.5)),
      Paint()..shader = buttonGradient,
    );
    
    // Metal clip
    final clipPath = Path();
    clipPath.moveTo(w * 0.58, h * 0.12);
    clipPath.lineTo(w * 0.62, h * 0.12);
    clipPath.lineTo(w * 0.62, h * 0.45);
    clipPath.quadraticBezierTo(w * 0.62, h * 0.5, w * 0.58, h * 0.5);
    clipPath.lineTo(w * 0.58, h * 0.48);
    clipPath.lineTo(w * 0.60, h * 0.48);
    clipPath.lineTo(w * 0.60, h * 0.14);
    clipPath.lineTo(w * 0.58, h * 0.14);
    clipPath.close();
    
    final clipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFE8E8E8),
        Color(0xFFC0C0C0),
        Color(0xFF909090),
        Color(0xFFB0B0B0),
      ],
    ).createShader(clipPath.getBounds());
    
    canvas.drawPath(clipPath, Paint()..shader = clipGradient);
    
    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    
    // Body highlight
    canvas.drawLine(
      Offset(w * 0.44, h * 0.15),
      Offset(w * 0.44, h * 0.52),
      highlightPaint,
    );
    
    // Clip highlight
    canvas.drawLine(
      Offset(w * 0.59, h * 0.15),
      Offset(w * 0.59, h * 0.42),
      highlightPaint..strokeWidth = 0.8,
    );
    
    canvas.restore();
  }
}

---

DOSYA: packages/drawing_ui/lib/src/painters/pen_icons/highlighter_icon_painter.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pen_icon_painter.dart';

class HighlighterIconPainter extends PenIconPainter {
  const HighlighterIconPainter({
    super.penColor = const Color(0xFFFFEB3B),
    super.isSelected = false,
    super.size = 56.0,
  });

  @override
  Path buildBodyPath(Rect rect) {
    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.width * 0.5, rect.height * 0.4),
        width: rect.width * 0.24,
        height: rect.height * 0.5,
      ),
      const Radius.circular(4),
    ));
    return path;
  }

  @override
  void paintShadow(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    // Colored shadow for glow effect
    final shadowPaint = Paint()
      ..color = penColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final shadowPath = Path();
    shadowPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.4), width: w * 0.24, height: h * 0.5),
      const Radius.circular(4),
    ));
    
    canvas.translate(2, 3);
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Also dark shadow for depth
    canvas.drawPath(shadowPath, Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    
    canvas.restore();
  }

  @override
  void paintBody(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.4),
      width: w * 0.24,
      height: h * 0.5,
    );
    
    // Semi-transparent colored body
    final bodyGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.5),   // highlight - more transparent
        penColor.withOpacity(0.75),  // mid
        penColor.withOpacity(0.85),  // core
        penColor.withOpacity(0.7),   // shadow side
      ],
      stops: const [0.0, 0.3, 0.65, 1.0],
    ).createShader(bodyRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..shader = bodyGradient,
    );
    
    // Cap (top, more opaque)
    final capRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.12),
      width: w * 0.25,
      height: h * 0.1,
    );
    
    final capGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.7),
        penColor.withOpacity(0.9),
        penColor,
        penColor.withOpacity(0.85),
      ],
    ).createShader(capRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..shader = capGradient,
    );
    
    canvas.restore();
  }

  @override
  void paintTip(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    // Chisel tip
    final tipPath = Path();
    tipPath.moveTo(w * 0.38, h * 0.65);
    tipPath.lineTo(w * 0.42, h * 0.82);
    tipPath.lineTo(w * 0.58, h * 0.82);
    tipPath.lineTo(w * 0.62, h * 0.65);
    tipPath.close();
    
    final tipGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        penColor.withOpacity(0.8),
        penColor.withOpacity(0.95),
        penColor,
        penColor.withOpacity(0.9),
      ],
    ).createShader(tipPath.getBounds());
    
    canvas.drawPath(tipPath, Paint()..shader = tipGradient);
    
    // Tip edge (darker for definition)
    final edgePaint = Paint()
      ..color = penColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawLine(
      Offset(w * 0.42, h * 0.82),
      Offset(w * 0.58, h * 0.82),
      edgePaint,
    );
    
    canvas.restore();
  }

  @override
  void paintHighlights(Canvas canvas, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-w / 2, -h / 2);
    
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    
    // Strong body highlight
    canvas.drawLine(
      Offset(w * 0.40, h * 0.2),
      Offset(w * 0.40, h * 0.6),
      highlightPaint,
    );
    
    // Cap highlight
    canvas.drawLine(
      Offset(w * 0.41, h * 0.09),
      Offset(w * 0.41, h * 0.15),
      highlightPaint..strokeWidth = 1.5,
    );
    
    canvas.restore();
  }
}

---

Diğer kalemler için de aynı prensipleri uygula:
- hardPencil: Pencil ile aynı, renkler daha açık/gri
- gelPen: Şeffaf gövde, içinde renkli mürekkep görünür
- dashedPen: Ballpoint benzeri, gövdede "---" işareti
- brushPen: İnce siyah gövde, kıl ucu detaylı
- marker: Kalın gövde, bullet tip
- neonHighlighter: Highlighter + glow efekti güçlü

HER KALEM İÇİN:
1. MaskFilter.blur ile soft shadow
2. Minimum 4 renk gradient
3. Sol üst ışık kaynağı
4. Metal parçalarda reflected light
5. Güçlü beyaz highlight (opacity 0.5+)

---

BİTİRDİĞİNDE:
1. flutter analyze
2. Tablet'te test et - premium görünüyor mu?
3. Commit: "refactor(ui): rewrite pen icons with premium quality"
```

---

Bu dosyayı Cursor'a ver. Tüm kalem painter'larını silip yeniden yazsın.
