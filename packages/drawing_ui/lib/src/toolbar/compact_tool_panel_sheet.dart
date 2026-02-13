import 'package:flutter/material.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/screens/drawing_screen_panels.dart';

/// Shows a tool's settings panel as a modal bottom sheet.
///
/// Wraps the existing panel widgets (PenSettingsPanel, EraserSettingsPanel, etc.)
/// inside a DraggableScrollableSheet for phone usage.
Future<void> showToolPanelSheet({
  required BuildContext context,
  required ToolType tool,
}) {
  // Don't show panel for tools that don't have one
  if (tool == ToolType.panZoom) {
    return Future.value();
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;

      return DraggableScrollableSheet(
        initialChildSize: 0.5,
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
                    child: buildActivePanel(
                      panel: tool,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
