import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_capsule.dart';
import 'package:drawing_ui/src/toolbar/elyanotes_nav_button.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';
import 'package:drawing_ui/src/toolbar/toolbar_overflow_menu.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';

/// Phone tool row (Row 2 of the phone chrome, < 600dp), see
/// docs/specs/52-editor-chrome.md, section 3:
/// ```
/// ( Undo Redo | tool tool tool ... overflow )
/// ```
/// One [ChromeCapsule] on the desk band with [ChromeSpacing.sm] side margins,
/// 48dp slots, and the last slot as overflow menu when tools do not fit
/// (never a scroll view). Tool panels open as bottom sheets via
/// [onPanelRequested]. Hidden in reader mode.
class CompactToolRow extends ConsumerStatefulWidget {
  const CompactToolRow({
    super.key,
    this.onAIPressed,
    this.onUndoPressed,
    this.onRedoPressed,
    this.onPanelRequested,
  });

  /// Row height: capsule plus [ChromeSpacing.xs] below it. Together with the
  /// 48dp nav row the phone chrome is inset + 104 (spec section 3).
  static const double height = ChromeCapsule.height + ChromeSpacing.xs;

  final VoidCallback? onAIPressed;
  final VoidCallback? onUndoPressed;
  final VoidCallback? onRedoPressed;

  /// Callback when a tool's panel should open as bottom sheet.
  final ValueChanged<ToolType>? onPanelRequested;

  @override
  ConsumerState<CompactToolRow> createState() => _CompactToolRowState();
}

class _CompactToolRowState extends ConsumerState<CompactToolRow> {
  @override
  Widget build(BuildContext context) {
    final isReaderMode = ref.watch(readerModeProvider);
    if (isReaderMode) return const SizedBox.shrink();

    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final tools = getGroupedVisibleTools(
      toolbarConfig,
      currentTool,
      lastEraser: eraserToolForMode(ref.watch(eraserSettingsProvider).mode),
    );
    final hasAI = widget.onAIPressed != null;

    return Container(
      height: CompactToolRow.height,
      color: ChromePalette.of(context).background,
      padding: const EdgeInsets.fromLTRB(
        ChromeSpacing.sm,
        0,
        ChromeSpacing.sm,
        ChromeSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fixed = ChromeCapsule.horizontalInset +
              (hasAI ? 3 : 2) * ChromeSizes.minTouchTarget +
              ChromeDivider.extent;
          final slots =
              ((constraints.maxWidth - fixed) / ChromeSizes.minTouchTarget)
                  .floor();
          final fits = tools.length <= slots;
          final shown = fits ? tools.length : (slots > 1 ? slots - 1 : 0);
          final hidden = tools.sublist(shown);

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ChromeCapsule(
                children: [
                  if (hasAI)
                    ElyanotesNavButton(
                      icon: ElyanotesIcons.sparkle,
                      tooltip: context.drawingStrings.toolbar.ai,
                      onPressed: widget.onAIPressed!,
                    ),
                  ToolbarUndoRedoButtons(
                    canUndo: canUndo,
                    canRedo: canRedo,
                    onUndo: widget.onUndoPressed,
                    onRedo: widget.onRedoPressed,
                  ),
                  const ChromeDivider(),
                  for (final tool in tools.take(shown))
                    _buildToolButton(tool, currentTool),
                  if (hidden.isNotEmpty)
                    ToolbarOverflowMenu(hiddenTools: hidden),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolButton(ToolType tool, ToolType currentTool) {
    final isPenGroup = penTools.contains(tool);
    final isHighlighterGroup = highlighterTools.contains(tool);
    final isEraserGroup = eraserTools.contains(tool);
    final hasPanel = toolsWithPanel.contains(tool);

    IconData? customIcon;
    if (isPenGroup && penTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    } else if (isHighlighterGroup && highlighterTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    } else if (isEraserGroup && eraserTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    }

    return ToolButton(
      toolType: tool,
      isSelected: isToolSelected(tool, currentTool),
      onPressed: () => _onToolPressed(tool),
      onPanelTap: hasPanel ? () => widget.onPanelRequested?.call(tool) : null,
      hasPanel: hasPanel,
      customIcon: customIcon,
    );
  }

  /// First tap selects; tapping the selected tool opens its bottom sheet.
  void _onToolPressed(ToolType tool) {
    ref.read(stickerPlacementProvider.notifier).cancel();
    ref.read(imagePlacementProvider.notifier).cancel();

    final currentTool = ref.read(currentToolProvider);
    if (isToolSelected(tool, currentTool)) {
      if (toolsWithPanel.contains(currentTool)) {
        widget.onPanelRequested?.call(currentTool);
      }
    } else {
      if (eraserTools.contains(tool) && !eraserTools.contains(currentTool)) {
        ref.read(previousToolProvider.notifier).state = currentTool;
      }
      ref.read(currentToolProvider.notifier).selectTool(tool);
      ref.read(activePanelProvider.notifier).state = null;
    }
  }
}
