import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_paste.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Floating pill that appears on long press to paste clipboard content.
class PasteContextMenu extends ConsumerWidget {
  final PasteMenuState state;
  const PasteContextMenu({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const menuWidth = 120.0;
    // 48dp: the whole pill is the tap target.
    const menuHeight = 48.0;
    final screenSize = MediaQuery.of(context).size;
    final label = context.drawingStrings.selection.paste;

    // Center menu horizontally on press point, clamp to screen
    final left = (state.screenPos.dx - menuWidth / 2)
        .clamp(8.0, screenSize.width - menuWidth - 8.0);
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
          child: _PasteButton(
            label: label,
            onTap: () {
              pasteFromClipboardAt(ref, state.canvasPos, context: context);
              ref.read(pasteMenuProvider.notifier).state = null;
            },
            child: Container(
              width: menuWidth,
              height: menuHeight,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(ChromeRadius.lg),
                boxShadow:
                    DrawingShadows.floating(Theme.of(context).brightness),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(ElyanotesIcons.paste,
                      size: 18, color: cs.onSurface),
                  const SizedBox(width: ChromeSpacing.sm),
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface,
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

/// The Paste pill as one labelled button for TalkBack.
class _PasteButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _PasteButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
