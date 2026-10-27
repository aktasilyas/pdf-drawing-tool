/// Hex and opacity text input row for the colour picker.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Parses `#RRGGBB` or `RRGGBB` into an opaque colour; null when invalid.
Color? parseHexColor(String input) {
  final hex = input.startsWith('#') ? input.substring(1) : input;
  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('FF$hex', radix: 16));
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
          child: PhosphorIcon(
            ElyanotesIcons.colorize,
            size: 18,
            color: const Color(0xFF4FC3F7),
          ),
        ),
        const SizedBox(width: 8),
        // Hex input
        Expanded(
          child: Container(
            height: 48,
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
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[#0-9A-Fa-f]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    onSubmitted: (value) {
                      final color = parseHexColor(value);
                      if (color != null) widget.onColorChanged(color);
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
            height: 48,
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
                          widget.color
                              .withValues(alpha: opacity.clamp(0.0, 1.0)),
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
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSave,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            color: Colors.transparent,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PhosphorIcon(
                ElyanotesIcons.plus,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
