import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/chrome_panel_parts.dart';
import 'package:drawing_ui/src/panels/text_preview_painter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';
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
    final palette = ChromePalette.of(context);
    final p = context.drawingStrings.panels;

    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChromePanelHeader(
            title: p.textTitle,
            onClose: () => ref.read(activePanelProvider.notifier).state = null,
          ),
          Text(
            p.textHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
          ),
          const SizedBox(height: ChromeSpacing.sm),
          TextPreview(
            fontSize: settings.fontSize,
            color: Color(settings.color),
            isBold: settings.isBold,
            isItalic: settings.isItalic,
            isUnderline: settings.isUnderline,
          ),
          const ChromeHairline(),
          GoodNotesSlider(
            label: p.size,
            value: settings.fontSize.clamp(8.0, 72.0),
            min: 8.0,
            max: 72.0,
            divisions: 16,
            displayValue: '${settings.fontSize.round()}pt',
            activeColor: palette.accent,
            onChanged: (v) =>
                ref.read(textSettingsProvider.notifier).setFontSize(v),
          ),
          const ChromeHairline(),
          ChromeSectionLabel(p.textColor),
          ColorPickerStrip(
            selectedColor: Color(settings.color),
            onColorSelected: (color) => ref
                .read(textSettingsProvider.notifier)
                .setColor(color.toARGB32()),
          ),
          const ChromeHairline(),
          ChromeSectionLabel(p.textStyle),
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
          key: const ValueKey('text-style-bold'),
          label: 'B', // l10n-ignore
          semanticLabel: context.drawingStrings.panels.bold,
          isSelected: isBold,
          fontWeight: FontWeight.bold,
          onTap: onBoldToggled,
        ),
        const SizedBox(width: ChromeSpacing.xs),
        _StyleToggle(
          key: const ValueKey('text-style-italic'),
          label: 'I', // l10n-ignore
          semanticLabel: context.drawingStrings.panels.italic,
          isSelected: isItalic,
          fontStyle: FontStyle.italic,
          onTap: onItalicToggled,
        ),
        const SizedBox(width: ChromeSpacing.xs),
        _StyleToggle(
          key: const ValueKey('text-style-underline'),
          label: 'U', // l10n-ignore
          semanticLabel: context.drawingStrings.panels.underline,
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
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.isSelected,
    required this.onTap,
    this.fontWeight,
    this.fontStyle,
    this.decoration,
  });

  final String label;
  final String semanticLabel;
  final bool isSelected;
  final VoidCallback onTap;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);

    return Semantics(
      button: true,
      toggled: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: ChromeSizes.minTouchTarget,
          child: Center(
            child: Container(
              width: ChromeIconButton.visualSize,
              height: ChromeIconButton.visualSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isSelected ? palette.accentContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(ChromeRadius.md),
                border: Border.all(
                  color: isSelected ? palette.accent : palette.border,
                ),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: fontWeight ?? FontWeight.normal,
                      fontStyle: fontStyle,
                      decoration: decoration,
                      color: isSelected ? palette.accent : palette.textMuted,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
