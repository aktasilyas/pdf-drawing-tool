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
      case PaperSizePreset.widescreen: return 'Genis (16:9)';
      case PaperSizePreset.custom: return 'Ozel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hPad = dense ? 8.0 : 12.0;
    final fontSize = dense ? 12.0 : 14.0;
    final iconSize = dense ? 14.0 : 18.0;
    final h = dense ? 36.0 : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
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
          _OrientationToggle(
            isLandscape: selectedSize.isLandscape,
            onToggle: () {
              onSizeSelected(
                selectedSize.isLandscape
                    ? selectedSize.portrait
                    : selectedSize.landscape,
              );
            },
            colorScheme: cs,
          ),
        ],
      ],
    );
  }
}

class _OrientationToggle extends StatelessWidget {
  final bool isLandscape;
  final VoidCallback onToggle;
  final ColorScheme colorScheme;

  const _OrientationToggle({
    required this.isLandscape,
    required this.onToggle,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: PhosphorIcon(
          isLandscape
              ? StarNoteIcons.orientationLandscape
              : StarNoteIcons.orientationPortrait,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
