# PHASE M4 — ADIM 1/4: PopoverPanel Widget Sistemi

## ÖZET
Mevcut AnchoredPanelController'ı baz alarak yeni PopoverPanel widget'ı oluştur. Daha küçük, animasyonlu, GoodNotes tarzı tooltip benzeri panel. Ok ile anchor'a bağlı.

## BRANCH
```bash
git checkout -b feature/pen-panel-modern
```

---

## MİMARİ KARAR

Mevcut AnchoredPanelController'ı DEĞİŞTİRME — yeni PopoverPanel ayrı widget. İkisi de projede kalır: AnchoredPanel büyük paneller için (toolbar editor gibi), PopoverPanel tool setting'ler için (pen, highlighter, eraser).

PopoverPanel farkları:
- Daha küçük: maxWidth 280dp (vs 300dp)
- Animasyonlu: scale(0.95→1.0) + fade(0→1), 150ms
- Daha yuvarlak: borderRadius 16dp
- Daha ince gölge: elevation 3
- Ok (arrow) her zaman yukarı, anchor'ın ortasını gösterir
- Barrier: transparent, tap ile kapatır

---

## AGENT GÖREVLERİ

### 👨‍💻 @flutter-developer — İmplementasyon

**Önce oku:**
- packages/drawing_ui/lib/src/widgets/anchored_panel.dart — mevcut AnchoredPanelController ve _PositionedPanelOverlay
- packages/drawing_ui/lib/src/utils/anchor_position_calculator.dart — AnchorPositionCalculator, ArrowDirection
- packages/drawing_ui/lib/src/widgets/panel_overlay.dart — PanelOverlay ve AnimatedPanelOverlay
- packages/drawing_ui/lib/src/theme/drawing_theme.dart — panel theme değerleri

**1) YENİ DOSYA: `packages/drawing_ui/lib/src/widgets/popover_panel.dart`**

Max 200 satır.

```dart
import 'package:flutter/material.dart';

/// Controller for showing/hiding popover panels.
///
/// Lighter alternative to AnchoredPanelController.
/// Shows compact panels with arrow pointing to anchor.
class PopoverController {
  OverlayEntry? _overlayEntry;
  bool get isShowing => _overlayEntry != null;

  /// Show popover below anchor widget.
  void show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required Widget child,
    VoidCallback? onDismiss,
    double maxWidth = 280,
  }) {
    hide();

    final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final anchorPos = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (_) => _PopoverOverlay(
        anchorPosition: anchorPos,
        anchorSize: anchorSize,
        screenSize: screenSize,
        maxWidth: maxWidth,
        onDismiss: () {
          hide();
          onDismiss?.call();
        },
        child: child,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  /// Hide the popover.
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Dispose.
  void dispose() {
    hide();
  }
}
```

**2) _PopoverOverlay widget — aynı dosyada**

```dart
class _PopoverOverlay extends StatefulWidget {
  const _PopoverOverlay({
    required this.anchorPosition,
    required this.anchorSize,
    required this.screenSize,
    required this.maxWidth,
    required this.onDismiss,
    required this.child,
  });

  final Offset anchorPosition;
  final Size anchorSize;
  final Size screenSize;
  final double maxWidth;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_PopoverOverlay> createState() => _PopoverOverlayState();
}

class _PopoverOverlayState extends State<_PopoverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Panel pozisyon hesaplama
    const padding = 12.0;
    const arrowHeight = 10.0;
    const arrowWidth = 20.0;
    
    // Panel top: anchor altı + boşluk + arrow
    final panelTop = widget.anchorPosition.dy + widget.anchorSize.height + 4 + arrowHeight;
    
    // Panel left: anchor'ın ortasına hizala, ekran sınırlarını kontrol et
    final anchorCenterX = widget.anchorPosition.dx + widget.anchorSize.width / 2;
    var panelLeft = anchorCenterX - widget.maxWidth / 2;
    panelLeft = panelLeft.clamp(padding, widget.screenSize.width - widget.maxWidth - padding);
    
    // Arrow pozisyonu: anchor center'a göre panel left'e relative
    final arrowLeft = (anchorCenterX - panelLeft - arrowWidth / 2)
        .clamp(16.0, widget.maxWidth - 16.0 - arrowWidth);

    return Stack(
      children: [
        // Barrier
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
            child: const SizedBox.expand(),
          ),
        ),

        // Popover + Arrow
        Positioned(
          top: panelTop - arrowHeight,
          left: panelLeft,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {}, // Panel tap absorb
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arrow (yukarı ok)
                    Padding(
                      padding: EdgeInsets.only(left: arrowLeft),
                      child: CustomPaint(
                        size: const Size(arrowWidth, arrowHeight),
                        painter: _ArrowPainter(
                          color: colorScheme.surfaceContainerHigh,
                          borderColor: colorScheme.outlineVariant,
                        ),
                      ),
                    ),

                    // Panel body
                    Container(
                      constraints: BoxConstraints(maxWidth: widget.maxWidth),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

**3) _ArrowPainter — aynı dosyada**

```dart
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({
    required this.color,
    required this.borderColor,
  });

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)         // Tepe
      ..lineTo(size.width, size.height)     // Sağ alt
      ..lineTo(0, size.height)              // Sol alt
      ..close();

    // Fill
    canvas.drawPath(path, Paint()..color = color);
    
    // Border (sadece sol ve sağ kenar, alt kenar panel ile birleşiyor)
    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
```

**4) GÜNCELLE: Barrel exports**

```dart
// widgets/widgets.dart barrel:
export 'popover_panel.dart';

// drawing_ui.dart:
// zaten widgets.dart export ediliyor, otomatik gelir
```

**5) Doğrulama:**
```bash
cd packages/drawing_ui && flutter analyze && flutter test
```

**KURALLAR:**
- PopoverController API'si AnchoredPanelController ile benzer ama bağımsız
- Panel rengi: colorScheme.surfaceContainerHigh (theme uyumlu)
- Border: colorScheme.outlineVariant, 0.5dp
- Arrow: aynı renklerle, panel body ile seamless birleşim
- Animasyon: scale(0.95→1.0) + fade(0→1), 150ms, easeOut
- maxWidth default 280dp
- Mevcut AnchoredPanel'e DOKUNMA
- popover_panel.dart max 200 satır

---

### 🧪 @qa-engineer — Test

```dart
void main() {
  group('PopoverController', () {
    test('initially not showing', () {
      final controller = PopoverController();
      expect(controller.isShowing, false);
    });

    test('hide when not showing does nothing', () {
      final controller = PopoverController();
      controller.hide(); // No crash
      expect(controller.isShowing, false);
    });

    test('dispose hides overlay', () {
      final controller = PopoverController();
      controller.dispose();
      expect(controller.isShowing, false);
    });
  });

  group('_ArrowPainter', () {
    test('shouldRepaint on color change', () {
      final p1 = _ArrowPainter(color: Colors.white, borderColor: Colors.grey);
      final p2 = _ArrowPainter(color: Colors.black, borderColor: Colors.grey);
      expect(p2.shouldRepaint(p1), true);
    });
  });
}
```

---

## COMMIT
```
feat(ui): add PopoverPanel widget system for tool settings

- PopoverController: show/hide overlay with anchor positioning
- Animated popover: scale + fade (150ms), 280dp max width
- Arrow painter pointing to anchor center
- Theme-aware colors, dark mode compatible
- Separate from AnchoredPanel (both coexist)
```

## SONRAKİ ADIM
Adım 2: Pen Settings Panel yeniden tasarım — canlı stroke preview + kalem tipi seçimi + slider'lar
