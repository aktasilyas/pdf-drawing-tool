/// Shared UI components for the color picker.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HSV Picker Box - 160x160 gradient for color selection
class HSVPickerBox extends StatefulWidget {
  const HSVPickerBox({
    super.key,
    required this.hsvColor,
    required this.onColorChanged,
  });

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onColorChanged;

  @override
  State<HSVPickerBox> createState() => _HSVPickerBoxState();
}

class _HSVPickerBoxState extends State<HSVPickerBox> {
  void _handlePositionUpdate(Offset globalPosition, BoxConstraints constraints) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final localPosition = box.globalToLocal(globalPosition);
    final saturation = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final value = 1.0 - (localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
    
    widget.onColorChanged(
      widget.hsvColor.withSaturation(saturation).withValue(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _handlePositionUpdate(details.globalPosition, constraints),
          onPanStart: (details) => _handlePositionUpdate(details.globalPosition, constraints),
          onPanUpdate: (details) => _handlePositionUpdate(details.globalPosition, constraints),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF424242)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: HSVBoxPainter(
                  hue: widget.hsvColor.hue,
                  saturation: widget.hsvColor.saturation,
                  value: widget.hsvColor.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter for HSV color box
class HSVBoxPainter extends CustomPainter {
  const HSVBoxPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    // Background with hue
    final hueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    final huePaint = Paint()..color = hueColor;
    canvas.drawRect(Offset.zero & size, huePaint);

    // White gradient (left to right)
    final whiteGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Colors.white.withAlpha(0)],
    );
    final whiteShader = whiteGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = whiteShader);

    // Black gradient (top to bottom)
    final blackGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.black.withAlpha(0), Colors.black],
    );
    final blackShader = blackGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = blackShader);

    // Selector
    final selectorX = saturation * size.width;
    final selectorY = (1 - value) * size.height;
    final selectorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(selectorX, selectorY),
      8,
      selectorPaint,
    );
  }

  @override
  bool shouldRepaint(HSVBoxPainter oldDelegate) =>
      hue != oldDelegate.hue ||
      saturation != oldDelegate.saturation ||
      value != oldDelegate.value;
}

/// Hue Slider - Rainbow gradient
class HueSlider extends StatelessWidget {
  const HueSlider({
    super.key,
    required this.hue,
    required this.onChanged,
  });

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF424242)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Rainbow gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const HSVColor.fromAHSV(1.0, 0, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 60, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 120, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 180, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 240, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 300, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 360, 1.0, 1.0).toColor(),
                  ],
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: hue,
                min: 0,
                max: 360,
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opacity Slider - Checkerboard + color gradient
class OpacitySlider extends StatelessWidget {
  const OpacitySlider({
    super.key,
    required this.color,
    required this.opacity,
    required this.onChanged,
  });

  final Color color;
  final double opacity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF424242)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Checkerboard
            CustomPaint(
              size: const Size(double.infinity, 24),
              painter: const CheckerboardPainter(),
            ),
            // Color gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0),
                    color.withValues(alpha: 1),
                  ],
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: opacity,
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkerboard pattern painter
class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 8.0;
    final paint = Paint();
    
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        paint.color = isEven ? const Color(0xFFCCCCCC) : const Color(0xFFFFFFFF);
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Hex + Opacity Input Row
class HexOpacityInput extends StatefulWidget {
  const HexOpacityInput({
    super.key,
    required this.color,
    required this.opacity,
    required this.showOpacity,
    required this.onColorChanged,
    required this.onSave,
  });

  final Color color;
  final double opacity;
  final bool showOpacity;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onSave;

  @override
  State<HexOpacityInput> createState() => _HexOpacityInputState();
}

class _HexOpacityInputState extends State<HexOpacityInput> {
  late TextEditingController _hexController;
  late TextEditingController _opacityController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: _colorToHex(widget.color));
    _opacityController = TextEditingController(
      text: (widget.opacity * 100).round().toString(),
    );
  }

  @override
  void didUpdateWidget(HexOpacityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hexController.text = _colorToHex(widget.color);
    }
    if (oldWidget.opacity != widget.opacity) {
      _opacityController.text = (widget.opacity * 100).round().toString();
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return r + g + b;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Eyedropper icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.colorize,
            size: 18,
            color: Color(0xFF4FC3F7),
          ),
        ),
        const SizedBox(width: 8),
        // Hex input
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  '#',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE0E0E0),
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (value) {
                      if (value.length == 6) {
                        final color = Color(int.parse('FF$value', radix: 16));
                        widget.onColorChanged(color);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showOpacity) ...[
          const SizedBox(width: 8),
          // Opacity input
          SizedBox(
            width: 60,
            height: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _opacityController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE0E0E0),
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onSubmitted: (value) {
                        final opacity = (int.tryParse(value) ?? 100) / 100;
                        widget.onColorChanged(
                          widget.color.withValues(alpha: opacity.clamp(0.0, 1.0)),
                        );
                      },
                    ),
                  ),
                  const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        // Save button
        GestureDetector(
          onTap: widget.onSave,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Recent Colors Row
class RecentColorsRow extends StatelessWidget {
  const RecentColorsRow({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.take(12).map((color) {
        final isSelected = _colorsMatch(color, selectedColor);
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4FC3F7)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _colorsMatch(Color a, Color b) {
    return (a.r * 255).round() == (b.r * 255).round() &&
        (a.g * 255).round() == (b.g * 255).round() &&
        (a.b * 255).round() == (b.b * 255).round();
  }
}
