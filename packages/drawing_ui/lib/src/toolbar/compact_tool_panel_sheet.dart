import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';
import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';

/// Sheet height cap as a fraction of the screen; the sheet shrinks to content.
const double _maxHeightFraction = 0.6;

/// Shows a tool's settings panel as a modal bottom sheet.
///
/// Sets [activePanelProvider] so the panel's built-in X button
/// (which clears the provider) automatically closes the sheet.
Future<void> showToolPanelSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ToolType tool,
}) {
  if (tool == ToolType.panZoom) return Future.value();

  // Set active panel so panel X buttons can close the sheet.
  ref.read(activePanelProvider.notifier).state = tool;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: ChromePalette.of(context).textPrimary.withValues(alpha: 0.12),
    builder: (sheetContext) => _ToolPanelSheet(tool: tool),
  ).whenComplete(() {
    // Reset when sheet closes (swipe dismiss or X button).
    ref.read(activePanelProvider.notifier).state = null;
  });
}

/// Bottom sheet content that auto-closes when panel X button is pressed.
class _ToolPanelSheet extends ConsumerWidget {
  const _ToolPanelSheet({required this.tool});
  final ToolType tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ChromePalette.of(context);
    final activePanel = ref.watch(activePanelProvider);

    // When panel's X button sets activePanelProvider to null, pop the sheet.
    // Only pop if this modal route is still the current route — prevents
    // double-pop when the sheet is dismissed by drag (drag already pops once,
    // then whenComplete sets provider to null, which would trigger a second pop
    // that closes the Drawing Screen itself).
    ref.listen<ToolType?>(activePanelProvider, (prev, next) {
      if (next == null && context.mounted) {
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) {
          Navigator.of(context).pop();
        }
      }
    });

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightFraction,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ChromeRadius.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ChromeSpacing.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(ChromeSpacing.xxs),
                ),
                child: const SizedBox(width: 32, height: 4),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChromeSpacing.lg,
                ),
                // Follows the active panel: the pen picker can switch to the
                // highlighter while the sheet is open.
                child: buildActivePanel(panel: activePanel ?? tool),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
