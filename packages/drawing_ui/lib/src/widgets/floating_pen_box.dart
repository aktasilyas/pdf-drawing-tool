import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/chrome_roles.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/widgets/floating_pen_box_controls.dart';
import 'package:drawing_ui/src/widgets/floating_pen_box_slot.dart';

/// Floating pen box that appears on the canvas.
/// Draggable, collapsible, with edit mode for removing pens.
class FloatingPenBox extends ConsumerStatefulWidget {
  const FloatingPenBox({
    super.key,
    this.onPositionChanged,
    this.position = const Offset(12, 12),
    this.onOpenPenSettings,
  });

  final ValueChanged<Offset>? onPositionChanged;
  final Offset position;
  final void Function(ToolType toolType)? onOpenPenSettings;

  @override
  ConsumerState<FloatingPenBox> createState() => _FloatingPenBoxState();
}

class _FloatingPenBoxState extends ConsumerState<FloatingPenBox> {
  bool _isExpanded = true;
  bool _isEditMode = false;

  static const double _shadowBlur = 10;
  static const Offset _shadowOffset = Offset(0, 2);

  Axis get _boxAxis {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenWidth = view.physicalSize.width / view.devicePixelRatio;
    final horizontal = penBoxOpensHorizontally(
      position: widget.position,
      screenWidth: screenWidth,
    );
    return horizontal ? Axis.horizontal : Axis.vertical;
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(penBoxPresetsProvider);
    final activePresets = presets.where((p) => !p.isEmpty).toList();
    final colorScheme = Theme.of(context).colorScheme;

    if (activePresets.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Container(
      decoration: BoxDecoration(
        color: colorScheme.floatingSurface,
        borderRadius: BorderRadius.circular(ChromeRadius.md),
        border: colorScheme.outlinedFloatingBorder,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow
                .withValues(alpha: colorScheme.penBoxShadowAlpha),
            blurRadius: _shadowBlur,
            offset: _shadowOffset,
          ),
        ],
      ),
      child: _isExpanded
          ? _buildExpanded(activePresets, presets)
          : FloatingPenBoxCollapsed(
              count: activePresets.length,
              onExpand: () => setState(() => _isExpanded = true),
            ),
    );

    if (!_isExpanded) {
      return GestureDetector(
        onPanUpdate: (details) {
          widget.onPositionChanged?.call(details.delta);
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildExpanded(
    List<PenPreset> activePresets,
    List<PenPreset> allPresets,
  ) {
    final selectedIndex = ref.watch(selectedPresetIndexProvider);
    final axis = _boxAxis;

    return Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final preset in activePresets)
          _buildSlot(
            preset: preset,
            index: allPresets.indexOf(preset),
            selectedIndex: selectedIndex,
            axis: axis,
          ),
        FloatingPenBoxControls(
          boxAxis: axis,
          isEditMode: _isEditMode,
          onToggleEditMode: () => setState(() => _isEditMode = !_isEditMode),
          onCollapse: () => setState(() {
            _isExpanded = false;
            _isEditMode = false;
          }),
        ),
      ],
    );
  }

  Widget _buildSlot({
    required PenPreset preset,
    required int index,
    required int selectedIndex,
    required Axis axis,
  }) {
    final actions = ref.read(penBoxActionsProvider);
    return FloatingPenBoxSlot(
      preset: preset,
      boxAxis: axis,
      isSelected: index == selectedIndex,
      isEditMode: _isEditMode,
      onTap: () {
        if (!_isEditMode) actions.selectPreset(index);
      },
      onDoubleTap: () {
        if (!_isEditMode) actions.openEditor(preset);
      },
      onDelete: () => actions.deletePreset(index),
    );
  }
}
