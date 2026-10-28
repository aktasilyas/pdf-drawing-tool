import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';

/// Display name of an eraser tool; any other tool falls back to the generic
/// eraser name.
String eraserTypeLabel(ToolType type, DrawingStrings s) {
  return switch (type) {
    ToolType.pixelEraser => s.panels.eraserPixel,
    ToolType.strokeEraser => s.tools.strokeEraser,
    ToolType.lassoEraser => s.tools.lassoEraser,
    _ => s.tools.pixelEraser,
  };
}

/// Eraser type selector (pixel / stroke / lasso) built from
/// [ChromeIconButton]s.
class EraserTypeSelector extends StatelessWidget {
  const EraserTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final ToolType selectedType;
  final ValueChanged<ToolType> onTypeSelected;

  static const _types = [
    ToolType.pixelEraser,
    ToolType.strokeEraser,
    ToolType.lassoEraser,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _types.map((t) {
        return ChromeIconButton(
          key: ValueKey('eraser-type-${t.name}'),
          icon: _iconFor(t),
          selectedIcon: _selectedIconFor(t),
          iconSize: ChromeIconSizes.md,
          tooltip: eraserTypeLabel(t, context.drawingStrings),
          selected: t == selectedType,
          onPressed: () => onTypeSelected(t),
        );
      }).toList(),
    );
  }

  static IconData _iconFor(ToolType type) {
    return switch (type) {
      ToolType.pixelEraser => PhosphorIconsLight.sparkle,
      ToolType.strokeEraser => PhosphorIconsLight.broom,
      ToolType.lassoEraser => PhosphorIconsLight.selection,
      _ => PhosphorIconsLight.eraser,
    };
  }

  static IconData _selectedIconFor(ToolType type) {
    return switch (type) {
      ToolType.pixelEraser => PhosphorIconsRegular.sparkle,
      ToolType.strokeEraser => PhosphorIconsRegular.broom,
      ToolType.lassoEraser => PhosphorIconsRegular.selection,
      _ => PhosphorIconsLight.eraser,
    };
  }
}

/// Destructive "clear page" action: 48dp minimum height, `danger` tint.
class ClearPageButton extends StatelessWidget {
  const ClearPageButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final radius = BorderRadius.circular(ChromeRadius.md);
    return Material(
      color: palette.danger.withValues(alpha: 0.1),
      borderRadius: radius,
      child: InkWell(
        key: const ValueKey('eraser-clear-page'),
        onTap: onPressed,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ChromeSizes.minTouchTarget,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ElyanotesIcons.trash,
                size: ChromeIconSizes.md,
                color: palette.danger,
              ),
              const SizedBox(width: ChromeSpacing.sm),
              Flexible(
                child: Text(
                  context.drawingStrings.panels.clearPage,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.danger,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
