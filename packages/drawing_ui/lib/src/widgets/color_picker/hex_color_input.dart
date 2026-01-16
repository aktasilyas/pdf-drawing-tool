import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hex renk kodu input widget
class HexColorInput extends StatefulWidget {
  const HexColorInput({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;

  @override
  State<HexColorInput> createState() => _HexColorInputState();
}

class _HexColorInputState extends State<HexColorInput> {
  late TextEditingController _controller;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _colorToHex(widget.color));
  }

  @override
  void didUpdateWidget(HexColorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      final newHex = _colorToHex(widget.color);
      if (_controller.text.toUpperCase() != newHex) {
        _controller.text = newHex;
        _isValid = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).substring(2, 8).toUpperCase();
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      final value = int.tryParse('FF$hex', radix: 16);
      if (value != null) {
        return Color(value);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Renk önizleme
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.color.computeLuminance() > 0.8
                  ? Colors.grey.shade300
                  : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Hex input
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              prefixText: '#',
              prefixStyle: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _isValid ? Colors.grey.shade300 : Colors.red.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _isValid ? Colors.grey.shade300 : Colors.red.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _isValid
                      ? const Color(0xFF4A9DFF)
                      : Colors.red.shade400,
                  width: 1.5,
                ),
              ),
              hintText: 'FFFFFF',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
              LengthLimitingTextInputFormatter(6),
              _UpperCaseTextFormatter(),
            ],
            onChanged: (value) {
              if (value.length == 6) {
                final color = _hexToColor(value);
                if (color != null) {
                  setState(() => _isValid = true);
                  widget.onColorChanged(color);
                } else {
                  setState(() => _isValid = false);
                }
              } else {
                setState(() => _isValid = value.isEmpty || value.length < 6);
              }
            },
            onSubmitted: (value) {
              if (value.length == 6) {
                final color = _hexToColor(value);
                if (color != null) {
                  widget.onColorChanged(color);
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Büyük harfe çeviren formatter
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
