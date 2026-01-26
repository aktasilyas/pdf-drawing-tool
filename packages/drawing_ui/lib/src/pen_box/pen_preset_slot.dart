import 'package:flutter/material.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';

/// A single slot in the pen box for a pen preset.
///
/// Displays the pen color, thickness preview, and nib shape indicator.
/// Shows selection state with background and elevation changes.
class PenPresetSlot extends StatelessWidget {
  const PenPresetSlot({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.size,
  });

  /// The preset to display.
  final PenPreset preset;

  /// Whether this slot is currently selected.
  final bool isSelected;

  /// Callback when the slot is tapped.
  final VoidCallback onTap;

  /// Callback when the slot is long-pressed.
  final VoidCallback? onLongPress;

  /// Size of the slot (defaults to theme's penSlotSize).
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = DrawingTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slotSize = size ?? theme.penSlotSize;

    if (preset.isEmpty) {
      return _buildEmptySlot(context, slotSize, theme, colorScheme, isDark);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: theme.animationDuration,
        curve: theme.animationCurve,
        width: slotSize,
        height: slotSize,
        decoration: BoxDecoration(
          color: Colors.transparent, // No background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark 
                    ? colorScheme.primary.withValues(alpha: 0.4) // Even softer in dark mode
                    : colorScheme.primary.withValues(alpha: 0.5))
                : (isDark 
                    ? colorScheme.outline.withValues(alpha: 0.2) 
                    : colorScheme.outline.withValues(alpha: 0.3)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark 
                        ? colorScheme.primary.withValues(alpha: 0.1) // Very subtle in dark
                        : colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 4, // Even more compact
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Custom pen icon - clipped to show only top half
              SizedBox(
                width: slotSize,
                height: slotSize,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.6, // Show only top 60% of the pen
                    child: ToolPenIcon(
                      toolType: preset.toolType,
                      color: preset.color,
                      isSelected: isSelected,
                      size: slotSize * 0.9,
                    ),
                  ),
                ),
              ),

              // Thickness indicator (bottom bar)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: _ThicknessIndicator(
                  thickness: preset.thickness,
                  color: preset.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot(
      BuildContext context, double slotSize, DrawingTheme theme, ColorScheme colorScheme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: slotSize,
        height: slotSize,
        decoration: BoxDecoration(
          color: isDark 
              ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5) 
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: slotSize * 0.4,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A small thickness indicator bar.
class _ThicknessIndicator extends StatelessWidget {
  const _ThicknessIndicator({
    required this.thickness,
    required this.color,
  });

  final double thickness;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Normalize thickness to 1-4 scale for display
    final normalizedHeight = (thickness / 20.0).clamp(0.1, 1.0) * 4 + 1;

    return Container(
      height: normalizedHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(normalizedHeight / 2),
      ),
    );
  }
}

/// A compact pen preview for lists and menus.
class CompactPenPreview extends StatelessWidget {
  const CompactPenPreview({
    super.key,
    required this.preset,
    this.size = 32,
  });

  final PenPreset preset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (preset.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark 
              ? colorScheme.surfaceContainerHigh 
              : colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add,
          size: size * 0.5,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: preset.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: preset.color,
          width: 2,
        ),
      ),
      child: Center(
        child: ToolPenIcon(
          toolType: preset.toolType,
          color: preset.color,
          size: size * 0.7,
        ),
      ),
    );
  }
}
