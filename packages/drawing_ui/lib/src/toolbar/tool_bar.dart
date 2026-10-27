import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/chrome_capsule.dart';
import 'package:drawing_ui/src/toolbar/tool_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/toolbar_logic.dart';
import 'package:drawing_ui/src/toolbar/elyanotes_nav_button.dart';
import 'package:drawing_ui/src/toolbar/toolbar_nav_left.dart';
import 'package:drawing_ui/src/toolbar/toolbar_nav_sections.dart';
import 'package:drawing_ui/src/toolbar/toolbar_overflow_menu.dart';
import 'package:drawing_ui/src/toolbar/toolbar_widgets.dart';

/// Expanded toolbar (>=840px) — single-row layout combining navigation and
/// drawing tools.
///
/// Three floating [ChromeCapsule]s on a `background` band
/// (docs/specs/52-editor-chrome.md, section 3):
/// ```
/// [Nav]      [Undo Redo | tools... overflow]      [Actions]
/// ```
/// Tools that do not fit collapse into a trailing overflow menu; the tools
/// capsule never scrolls. In reader mode the tools capsule fades out while
/// the other capsules stay in place.
class ToolBar extends ConsumerStatefulWidget {
  const ToolBar({
    super.key,
    this.onAIPressed,
    this.onSettingsPressed,
    this.settingsButtonKey,
    this.toolButtonKeys,
    this.penGroupButtonKey,
    this.highlighterGroupButtonKey,
    this.documentTitle,
    this.onHomePressed,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
  });

  final VoidCallback? onAIPressed;
  final VoidCallback? onSettingsPressed;
  final GlobalKey? settingsButtonKey;
  final Map<ToolType, GlobalKey>? toolButtonKeys;
  final GlobalKey? penGroupButtonKey;
  final GlobalKey? highlighterGroupButtonKey;

  // Nav parameters
  final String? documentTitle;
  final VoidCallback? onHomePressed;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;

  @override
  ConsumerState<ToolBar> createState() => _ToolBarState();
}

class _ToolBarState extends ConsumerState<ToolBar> {
  /// Height of the band: capsule plus top and bottom padding.
  static const double _bandHeight =
      ChromeCapsule.height + ChromeSpacing.sm + ChromeSpacing.xs;

  /// Toolbar width from which the title pill may grow to [_wideTitleWidth].
  static const double _wideTitleBreakpoint = 1000;
  static const double _wideTitleWidth = 240;
  static const double _narrowTitleWidth = 160;

  final Map<ToolType, GlobalKey> _toolButtonKeys = {};

  @override
  void initState() {
    super.initState();
    for (final tool in ToolType.values) {
      _toolButtonKeys[tool] = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final isReaderMode = ref.watch(readerModeProvider);
    final pageCount = ref.watch(pageCountProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleMaxWidth = constraints.maxWidth >= _wideTitleBreakpoint
            ? _wideTitleWidth
            : _narrowTitleWidth;
        return Container(
          height: _bandHeight,
          color: palette.background,
          padding: const EdgeInsets.fromLTRB(
            ChromeSpacing.lg,
            ChromeSpacing.sm,
            ChromeSpacing.lg,
            ChromeSpacing.xs,
          ),
          child: Row(
            children: [
              ChromeCapsule(
                children: [
                  ToolbarNavLeft(
                    documentTitle: widget.documentTitle,
                    onHomePressed: widget.onHomePressed,
                    onRenameDocument: widget.onRenameDocument,
                    onDeleteDocument: widget.onDeleteDocument,
                    onSidebarToggle: widget.onSidebarToggle,
                    isSidebarOpen: widget.isSidebarOpen,
                    isReaderMode: isReaderMode,
                    pageCount: pageCount,
                    titleMaxWidth: titleMaxWidth,
                    showReaderBadge: false,
                  ),
                ],
              ),
              Expanded(child: _buildToolsArea(isReaderMode)),
              ChromeCapsule(
                children: [
                  ToolbarNavRight(
                    isReaderMode: isReaderMode,
                    onReaderToggle: () => _setReaderMode(!isReaderMode),
                    onShowRecordings: () => _openRecordingsTab(ref),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Centred tools capsule with a [ChromeSpacing.md] gap to its neighbours.
  Widget _buildToolsArea(bool isReaderMode) {
    final currentTool = ref.watch(currentToolProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final tools = getGroupedVisibleTools(
      toolbarConfig,
      currentTool,
      lastEraser: eraserToolForMode(ref.watch(eraserSettingsProvider).mode),
    );
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final hasAI = widget.onAIPressed != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fixed part: capsule inset, undo + redo, divider, optional AI.
          final fixed = ChromeCapsule.horizontalInset +
              (hasAI ? 3 : 2) * ChromeSizes.minTouchTarget +
              ChromeDivider.extent;
          final available = constraints.maxWidth - fixed;
          final slots = (available / ChromeSizes.minTouchTarget).floor();
          final fits = tools.length <= slots;
          final shown = fits ? tools.length : (slots > 1 ? slots - 1 : 0);
          final hidden = tools.sublist(shown);

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ExcludeFocus(
                excluding: isReaderMode,
                child: ExcludeSemantics(
                  excluding: isReaderMode,
                  child: IgnorePointer(
                    ignoring: isReaderMode,
                    child: AnimatedOpacity(
                      opacity: isReaderMode ? 0 : 1,
                      duration: ChromeDurations.instant,
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
                            onUndo: _undo,
                            onRedo: _redo,
                          ),
                          const ChromeDivider(),
                          for (final tool in tools.take(shown))
                            _buildToolButton(tool, currentTool),
                          if (hidden.isNotEmpty)
                            ToolbarOverflowMenu(hiddenTools: hidden),
                        ],
                      ),
                    ),
                  ),
                ),
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
    final selected = isToolSelected(tool, currentTool);
    final hasPanel = toolsWithPanel.contains(tool);

    final GlobalKey? buttonKey;
    if (isPenGroup) {
      buttonKey = widget.penGroupButtonKey;
    } else if (isHighlighterGroup) {
      buttonKey = widget.highlighterGroupButtonKey;
    } else {
      buttonKey = widget.toolButtonKeys?[tool];
    }

    IconData? customIcon;
    if (isPenGroup && penTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    } else if (isEraserGroup && eraserTools.contains(currentTool)) {
      customIcon = ToolButton.getIconForTool(currentTool);
    }

    return ToolButton(
      key: buttonKey,
      toolType: tool,
      isSelected: selected,
      buttonKey: _toolButtonKeys[tool],
      onPressed: () => _onToolPressed(tool),
      onPanelTap: hasPanel ? () => _onPanelTap(tool) : null,
      hasPanel: hasPanel,
      customIcon: customIcon,
    );
  }

  void _setReaderMode(bool value) =>
      ref.read(readerModeProvider.notifier).state = value;

  void _undo() => ref.read(historyManagerProvider.notifier).undo();

  void _redo() => ref.read(historyManagerProvider.notifier).redo();

  void _onToolPressed(ToolType tool) => handleToolPressed(ref, tool);

  void _onPanelTap(ToolType tool) {
    final active = ref.read(activePanelProvider);
    ref.read(activePanelProvider.notifier).state = active == tool ? null : tool;
  }

  void _openRecordingsTab(WidgetRef ref) {
    ref.read(sidebarFilterProvider.notifier).state = SidebarFilter.recordings;
    if (!widget.isSidebarOpen) widget.onSidebarToggle?.call();
  }

  GlobalKey? getToolButtonKey(ToolType tool) => _toolButtonKeys[tool];
}
