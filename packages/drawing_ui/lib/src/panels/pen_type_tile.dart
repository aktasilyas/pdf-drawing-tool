import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/panels/pen_preset_preview.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

// Mirrors AppSpacing / AppRadius (drawing_ui cannot import example_app).
const double _kSm = 8;
const double _kTileRadius = 12;
const double _kWellRadius = 8;
const double _kBorder = 1.5;
const double _kFocusBorder = 2;
const double _kHairline = 1;

const double _kWellWidth = 56;
const double _kWellHeight = 40;
const double _kLabelHeight = 32;
const double _kLabelLine = 16;
const double _kLabelFont = 11;

/// One selectable pen type: live stroke preview above a two-line label.
class PenTypeTile extends ConsumerStatefulWidget {
  const PenTypeTile({
    super.key,
    required this.tool,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ToolType tool;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  ConsumerState<PenTypeTile> createState() => _PenTypeTileState();
}

class _PenTypeTileState extends ConsumerState<PenTypeTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = DrawingTheme.of(context).animationDuration;
    final selected = widget.selected;
    final labelColor = selected ? scheme.primary : scheme.onSurfaceVariant;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          height: _kLabelLine / _kLabelFont,
          color: labelColor,
          fontWeight: selected ? FontWeight.w600 : null,
        );
    final scaler = MediaQuery.textScalerOf(context);
    final radius = BorderRadius.circular(_kTileRadius);
    final borderColor = scheme.primary;
    final border = _focused
        ? Border.all(color: borderColor, width: _kFocusBorder)
        : selected
            ? Border.all(color: borderColor, width: _kBorder)
            : null;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (v) => setState(() => _focused = v),
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.onSurface.withValues(alpha: 0.08),
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: _kSm),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: radius,
              border: border,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PreviewWell(tool: widget.tool),
                const SizedBox(height: _kSm),
                SizedBox(
                  height: scaler.scale(_kLabelHeight),
                  child: Text(
                    widget.label,
                    style: labelStyle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewWell extends ConsumerWidget {
  const _PreviewWell({required this.tool});

  final ToolType tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final style = ref.watch(strokeStyleForToolProvider(tool));
    final page = ref.watch(canvasColorSchemeProvider).background;
    return ExcludeSemantics(
      child: Container(
        width: _kWellWidth,
        height: _kWellHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: page,
          borderRadius: BorderRadius.circular(_kWellRadius),
          border: Border.all(color: scheme.outlineVariant, width: _kHairline),
        ),
        child: PenPresetPreview(
          penType: tool.penType!,
          style: style,
          background: page,
        ),
      ),
    );
  }
}
