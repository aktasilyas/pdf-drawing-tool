import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/widgets/pen_icon_widget.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';

/// Compact pen type picker — first-level popover.
/// Shows list of pen types. Tap selects pen and triggers onPenSelected.
class PenTypePicker extends ConsumerWidget {
  const PenTypePicker({super.key, this.onPenSelected});

  final ValueChanged<ToolType>? onPenSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: penTools.map((pen) {
          final isSelected = pen == currentTool;
          final label = pen.penType?.config.displayNameTr ?? pen.displayName;

          return InkWell(
            onTap: () {
              ref.read(currentToolProvider.notifier).state = pen;
              onPenSelected?.call(pen);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: ToolPenIcon(
                      toolType: pen,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      isSelected: isSelected,
                      size: 24,
                      orientation: PenOrientation.vertical,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded,
                        size: 18, color: colorScheme.primary),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
