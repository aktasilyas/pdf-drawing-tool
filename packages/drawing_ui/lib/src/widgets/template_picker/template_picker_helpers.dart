import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/template_preview_widget.dart';

/// Paper color presets for the dropdown.
enum PaperColorPreset {
  white(Color(0xFFFFFFFF)),
  cream(Color(0xFFFFFDE7)),
  black(Color(0xFF303030));

  const PaperColorPreset(this.color);
  final Color color;
}

/// Localized name of a paper colour preset.
String paperColorPresetLabel(TemplateStrings s, PaperColorPreset preset) =>
    switch (preset) {
      PaperColorPreset.white => s.colorWhite,
      PaperColorPreset.cream => s.colorCream,
      PaperColorPreset.black => s.colorBlack,
    };

/// Template picker sonucu
class TemplatePickerResult {
  final Template template;
  final PaperSize paperSize;
  final Color? lineColor;
  final Color? backgroundColor;
  final Cover? cover;

  const TemplatePickerResult({
    required this.template,
    required this.paperSize,
    this.lineColor,
    this.backgroundColor,
    this.cover,
  });
}

/// Tablet preview panel — template önizleme (sağ taraf)
class TemplatePickerPreviewPanel extends StatelessWidget {
  final Template template;
  final Color paperColor;
  final PaperSize paperSize;

  const TemplatePickerPreviewPanel({
    super.key,
    required this.template,
    required this.paperColor,
    required this.paperSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: Column(children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 210 / 297,
              child: TemplatePreviewWidget(
                template: template,
                backgroundColorOverride: paperColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(context.drawingStrings.templates.templateName(template),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(paperSize.preset.name.toUpperCase(),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

/// Paper color dropdown
class PaperColorDropdown extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final double height;

  const PaperColorDropdown({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    this.height = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);

    // Build effective presets — add current color if not in defaults
    final s = context.drawingStrings.templates;
    final effectivePresets = <(String, Color)>[
      for (final p in PaperColorPreset.values)
        (paperColorPresetLabel(s, p), p.color),
    ];
    final isCustom = !effectivePresets.any((e) => e.$2 == selectedColor);
    if (isCustom) {
      effectivePresets.add((s.custom, selectedColor));
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: radius,
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Color>(
          value: selectedColor,
          isDense: true,
          icon: PhosphorIcon(ElyanotesIcons.caretDown,
              size: 14, color: cs.onSurfaceVariant),
          style: TextStyle(fontSize: 12, color: cs.onSurface),
          dropdownColor: cs.surfaceContainerHighest,
          items: effectivePresets.map((e) {
            return DropdownMenuItem(
              value: e.$2,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: e.$2,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: cs.outline.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(e.$1),
              ]),
            );
          }).toList(),
          onChanged: (c) {
            if (c != null) onColorChanged(c);
          },
        ),
      ),
    );
  }
}
