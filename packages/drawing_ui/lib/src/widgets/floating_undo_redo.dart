import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Floating undo/redo pill button (GoodNotes style)
/// Positioned at top-left of canvas, above content
class FloatingUndoRedo extends ConsumerWidget {
  const FloatingUndoRedo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UndoRedoButton(
              icon: StarNoteIcons.undo,
              tooltip: 'Geri al',
              enabled: canUndo,
              onPressed: () => ref.read(historyManagerProvider.notifier).undo(),
              isFirst: true,
            ),
            Container(
              width: 1,
              height: 24,
              color: colorScheme.outlineVariant,
            ),
            _UndoRedoButton(
              icon: StarNoteIcons.redo,
              tooltip: 'İleri al',
              enabled: canRedo,
              onPressed: () => ref.read(historyManagerProvider.notifier).redo(),
              isFirst: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoRedoButton extends StatelessWidget {
  final PhosphorIconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isFirst;

  const _UndoRedoButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(22) : Radius.zero,
              right: isFirst ? Radius.zero : const Radius.circular(22),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: PhosphorIcon(
                icon,
                size: 20,
                color: enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
