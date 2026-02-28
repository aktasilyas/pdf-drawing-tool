import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-spectrum color picker: Hue × Saturation 2D area + Value slider.
/// Optionally shows an opacity slider for highlighter tools.
class SpectrumPicker extends StatelessWidget {
  const SpectrumPicker({
    super.key,
    required this.hsvColor,
    required this.onColorChanged,
    this.showOpacity = false,
    this.opacity = 1.0,
    this.onOpacityChanged,
  });

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onColorChanged;
  final bool showOpacity;
  final double opacity;
  final ValueChanged<double>? onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HueSatArea(
          hsvColor: hsvColor,
          onChanged: (h, s) =>
              onColorChanged(hsvColor.withHue(h).withSaturation(s)),
        ),
        const SizedBox(height: 16),
        _GradientSliderRow(
          value: hsvColor.value,
          colors: [Colors.black, hsvColor.withValue(1).toColor()],
          onChanged: (v) => onColorChanged(hsvColor.withValue(v)),
        ),
        if (showOpacity && onOpacityChanged != null) ...[
          const SizedBox(height: 12),
          _GradientSliderRow(
            value: opacity,
            colors: [
              hsvColor.toColor().withValues(alpha: 0),
              hsvColor.toColor().withValues(alpha: 1),
            ],
            onChanged: onOpacityChanged!,
          ),
        ],
      ],
    );
  }
}

/// 2D picker area: horizontal = hue, vertical = saturation.
class _HueSatArea extends StatelessWidget {
  const _HueSatArea({required this.hsvColor, required this.onChanged});

  final HSVColor hsvColor;
  final void Function(double hue, double saturation) onChanged;

  void _update(Offset global, BuildContext ctx, Size size) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global);
    onChanged(
      (local.dx / size.width).clamp(0.0, 1.0) * 360,
      (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = w * 0.78;
      final size = Size(w, h);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _update(d.globalPosition, context, size),
        onPanStart: (d) => _update(d.globalPosition, context, size),
        onPanUpdate: (d) => _update(d.globalPosition, context, size),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF424242)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: CustomPaint(
              size: size,
              painter: _HueSatPainter(
                value: hsvColor.value,
                selHue: hsvColor.hue,
                selSat: hsvColor.saturation,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _HueSatPainter extends CustomPainter {
  _HueSatPainter({
    required this.value,
    required this.selHue,
    required this.selSat,
  });

  final double value;
  final double selHue;
  final double selSat;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Layer 1: horizontal rainbow gradient (hue 0° → 360°)
    final hueColors = List.generate(
      13,
      (i) => HSVColor.fromAHSV(1, i * 30.0, 1, 1).toColor(),
    );
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: hueColors).createShader(rect),
    );

    // Layer 2: white → transparent top→bottom (inverse saturation)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0x00FFFFFF)],
        ).createShader(rect),
    );

    // Layer 3: darken by value
    if (value < 1.0) {
      canvas.drawRect(
        rect,
        Paint()..color = Colors.black.withValues(alpha: 1.0 - value),
      );
    }

    // Selector circle
    final sx = (selHue / 360) * size.width;
    final sy = selSat * size.height;
    final center = Offset(sx, sy);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center,
      11.5,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_HueSatPainter old) =>
      value != old.value || selHue != old.selHue || selSat != old.selSat;
}

/// Gradient slider with percentage label.
class _GradientSliderRow extends StatelessWidget {
  const _GradientSliderRow({
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF424242)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                ),
              ),
              SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 28,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                  trackShape: RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.transparent,
                  inactiveColor: Colors.transparent,
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: 48,
        child: Text(
          '${(value * 100).round()} %',
          style: GoogleFonts.sourceSerif4(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ]);
  }
}
