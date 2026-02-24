import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_actions_provider.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Floating pill that appears on long press to paste clipboard content.
class PasteContextMenu extends ConsumerWidget {
  final PasteMenuState state;
  const PasteContextMenu({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const menuWidth = 120.0;
    const menuHeight = 40.0;
    final screenSize = MediaQuery.of(context).size;

    // Center menu horizontally on press point, clamp to screen
    final left =
        (state.screenPos.dx - menuWidth / 2).clamp(8.0, screenSize.width - menuWidth - 8.0);
    // Position above the press point
    var top = state.screenPos.dy - menuHeight - 12;
    if (top < 8) top = state.screenPos.dy + 12;

    return Positioned(
      left: left,
      top: top,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {},
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              pasteFromClipboardAt(ref, state.canvasPos);
              ref.read(pasteMenuProvider.notifier).state = null;
            },
            child: Container(
              width: menuWidth,
              height: menuHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(StarNoteIcons.paste, size: 18,
                      color: Colors.black87),
                  const SizedBox(width: 6),
                  const Text(
                    'Yapıştır',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
