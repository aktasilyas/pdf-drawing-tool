import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/panels/text_preview_painter.dart';
import 'package:drawing_ui/src/panels/tool_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/color_picker_strip.dart';
import 'package:drawing_ui/src/widgets/goodnotes_slider.dart';

/// Settings panel for the text tool.
///
/// Matches eraser/highlighter panel pattern with font size slider,
/// square color chips, palette button, and B/I/U toggles.
class TextSettingsPanel extends ConsumerWidget {
  const TextSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(textSettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Title + Close --
          Row(
            children: [
              Expanded(
                child: Text(
                  'Metin Aracı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              PanelCloseButton(
                onTap: () =>
                    ref.read(activePanelProvider.notifier).state = null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tuvale dokunarak metin kutusu ekleyin.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // -- Text Preview --
          TextPreview(
            fontSize: settings.fontSize,
            color: Color(settings.color),
            isBold: settings.isBold,
            isItalic: settings.isItalic,
            isUnderline: settings.isUnderline,
          ),
          const SizedBox(height: 16),

          // -- Font Size Slider --
          GoodNotesSlider(
            label: 'Boyut',
            value: settings.fontSize.clamp(8.0, 72.0),
            min: 8.0,
            max: 72.0,
            divisions: 16,
            displayValue: '${settings.fontSize.round()}pt',
            activeColor: cs.primary,
            onChanged: (v) =>
                ref.read(textSettingsProvider.notifier).setFontSize(v),
          ),
          const SizedBox(height: 20),

          // -- Color Section --
          Text(
            'Renk',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ColorPickerStrip(
            selectedColor: Color(settings.color),
            onColorSelected: (color) => ref
                .read(textSettingsProvider.notifier)
                .setColor(color.toARGB32()),
          ),
          const SizedBox(height: 20),

          // -- Style Section --
          Text(
            'Stil',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _StyleButtonRow(
            isBold: settings.isBold,
            isItalic: settings.isItalic,
            isUnderline: settings.isUnderline,
            onBoldToggled: () =>
                ref.read(textSettingsProvider.notifier).toggleBold(),
            onItalicToggled: () =>
                ref.read(textSettingsProvider.notifier).toggleItalic(),
            onUnderlineToggled: () =>
                ref.read(textSettingsProvider.notifier).toggleUnderline(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Style Button Row (B / I / U)
// ---------------------------------------------------------------------------

class _StyleButtonRow extends StatelessWidget {
  const _StyleButtonRow({
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.onBoldToggled,
    required this.onItalicToggled,
    required this.onUnderlineToggled,
  });

  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final VoidCallback onBoldToggled;
  final VoidCallback onItalicToggled;
  final VoidCallback onUnderlineToggled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StyleToggle(
          label: 'B',
          isSelected: isBold,
          fontWeight: FontWeight.bold,
          onTap: onBoldToggled,
        ),
        const SizedBox(width: 8),
        _StyleToggle(
          label: 'I',
          isSelected: isItalic,
          fontStyle: FontStyle.italic,
          onTap: onItalicToggled,
        ),
        const SizedBox(width: 8),
        _StyleToggle(
          label: 'U',
          isSelected: isUnderline,
          decoration: TextDecoration.underline,
          onTap: onUnderlineToggled,
        ),
      ],
    );
  }
}

class _StyleToggle extends StatelessWidget {
  const _StyleToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.fontWeight,
    this.fontStyle,
    this.decoration,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? null
              : Border.all(
                  color: cs.outline.withValues(alpha: 0.3),
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: fontWeight ?? FontWeight.normal,
              fontStyle: fontStyle,
              decoration: decoration,
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
