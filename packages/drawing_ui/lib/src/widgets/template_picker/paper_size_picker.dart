import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Kağıt boyutu seçici - dropdown style
class PaperSizePicker extends StatelessWidget {
  final PaperSize selectedSize;
  final ValueChanged<PaperSize> onSizeSelected;
  final bool showLandscapeToggle;

  const PaperSizePicker({
    super.key,
    required this.selectedSize,
    required this.onSizeSelected,
    this.showLandscapeToggle = true,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PaperSizePreset>(
              value: selectedSize.preset,
              icon: PhosphorIcon(
                StarNoteIcons.caretDown,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              dropdownColor: colorScheme.surfaceContainerHighest,
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
            colorScheme: colorScheme,
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
