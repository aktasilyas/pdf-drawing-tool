import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// GoodNotes-style horizontal pen type picker for popover.
class PenTypePicker extends ConsumerWidget {
  const PenTypePicker({super.key, this.onPenSelected});

  final ValueChanged<ToolType>? onPenSelected;

  /// Gösterilecek 5 kalem tipi (sıralı)
  static const _pickerPens = [
    ToolType.pencil,        // Kurşun Kalem
    ToolType.ballpointPen,  // Tükenmez Kalem
    ToolType.dashedPen,     // Kesik Çizgi
    ToolType.brushPen,      // Fırça Kalem
    ToolType.rulerPen,      // Cetvelli Kalem
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _pickerPens.map((pen) {
          final isSelected = pen == currentTool ||
              (!_pickerPens.contains(currentTool) && pen == ToolType.ballpointPen);
          final label = _getLabel(pen);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(currentToolProvider.notifier).state = pen;
                onPenSelected?.call(pen);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // İkon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        _getIcon(pen),
                        size: 22,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _getLabel(ToolType type) {
    switch (type) {
      case ToolType.pencil: return 'Kurşun\nKalem';
      case ToolType.ballpointPen: return 'Tükenmez\nKalem';
      case ToolType.dashedPen: return 'Kesik\nÇizgi';
      case ToolType.brushPen: return 'Fırça\nKalem';
      case ToolType.rulerPen: return 'Cetvelli\nKalem';
      default: return type.displayName;
    }
  }

  static PhosphorIconData _getIcon(ToolType type) {
    switch (type) {
      case ToolType.pencil: return PhosphorIconsLight.pencilSimple;
      case ToolType.ballpointPen: return PhosphorIconsLight.pen;
      case ToolType.dashedPen: return PhosphorIconsLight.penNibStraight;
      case ToolType.brushPen: return PhosphorIconsLight.paintBrush;
      case ToolType.rulerPen: return PhosphorIconsLight.ruler;
      default: return PhosphorIconsLight.pen;
    }
  }
}
