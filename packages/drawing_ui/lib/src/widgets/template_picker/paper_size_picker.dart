import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Kagit boyutu secici - dropdown style
class PaperSizePicker extends StatelessWidget {
  final PaperSize selectedSize;
  final ValueChanged<PaperSize> onSizeSelected;
  final bool showLandscapeToggle;

  /// When true, uses smaller padding and font for compact bottom bars.
  final bool dense;

  const PaperSizePicker({
    super.key,
    required this.selectedSize,
    required this.onSizeSelected,
    this.showLandscapeToggle = true,
    this.dense = false,
  });

  static const _presets = [
    PaperSizePreset.a4,
    PaperSizePreset.a5,
    PaperSizePreset.a6,
    PaperSizePreset.letter,
    PaperSizePreset.legal,
    PaperSizePreset.square,
    PaperSizePreset.widescreen,
  ];

  String _getPresetName(PaperSizePreset preset) {
    switch (preset) {
      case PaperSizePreset.a4: return 'A4';
      case PaperSizePreset.a5: return 'A5';
      case PaperSizePreset.a6: return 'A6';
      case PaperSizePreset.letter: return 'Letter';
      case PaperSizePreset.legal: return 'Legal';
      case PaperSizePreset.square: return 'Kare';
      case PaperSizePreset.widescreen: return 'Geniş (16:9)';
      case PaperSizePreset.custom: return 'Özel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hPad = dense ? 8.0 : 12.0;
    final fontSize = dense ? 12.0 : 14.0;
    final iconSize = dense ? 14.0 : 18.0;
    final h = dense ? 36.0 : null;
    final border = Border.all(color: cs.outline.withValues(alpha: 0.2));
    final radius = BorderRadius.circular(8);
    final decoration = BoxDecoration(
      color: cs.surfaceContainerHigh, borderRadius: radius, border: border,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          decoration: decoration,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PaperSizePreset>(
              value: selectedSize.preset,
              isDense: dense,
              icon: PhosphorIcon(StarNoteIcons.caretDown,
                  size: iconSize, color: cs.onSurfaceVariant),
              style: TextStyle(fontSize: fontSize, color: cs.onSurface),
              dropdownColor: cs.surfaceContainerHighest,
              items: _presets.map((preset) {
                return DropdownMenuItem(
                  value: preset,
                  child: Text(_getPresetName(preset)),
                );
              }).toList(),
              onChanged: (preset) {
                if (preset != null) {
                  final newSize = PaperSize.fromPreset(preset);
                  onSizeSelected(
                    selectedSize.isLandscape ? newSize.landscape : newSize,
                  );
                }
              },
            ),
          ),
        ),
        if (showLandscapeToggle) ...[
          const SizedBox(width: 8),
          Container(
            height: h,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            decoration: decoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: selectedSize.isLandscape,
                isDense: dense,
                icon: PhosphorIcon(StarNoteIcons.caretDown,
                    size: iconSize, color: cs.onSurfaceVariant),
                style: TextStyle(fontSize: fontSize, color: cs.onSurface),
                dropdownColor: cs.surfaceContainerHighest,
                items: const [
                  DropdownMenuItem(value: false, child: Text('Dikey')),
                  DropdownMenuItem(value: true, child: Text('Yatay')),
                ],
                onChanged: (isLandscape) {
                  if (isLandscape == null) return;
                  onSizeSelected(
                    isLandscape
                        ? selectedSize.landscape
                        : selectedSize.portrait,
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
