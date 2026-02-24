import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

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

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Panel content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: buildActivePanel(panel: tool),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
