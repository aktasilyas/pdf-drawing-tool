import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';

/// Floating undo/redo pill button (GoodNotes style)
/// Positioned at top-left of canvas, above content
class FloatingUndoRedo extends ConsumerWidget {
  const FloatingUndoRedo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
            // Undo button
            _UndoRedoButton(
              icon: Icons.undo_rounded,
              enabled: canUndo,
              onPressed: () => ref.read(historyManagerProvider.notifier).undo(),
              isFirst: true,
            ),
            // Divider
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.shade200,
            ),
            // Redo button
            _UndoRedoButton(
              icon: Icons.redo_rounded,
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
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isFirst;

  const _UndoRedoButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(22) : Radius.zero,
          right: isFirst ? Radius.zero : const Radius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
