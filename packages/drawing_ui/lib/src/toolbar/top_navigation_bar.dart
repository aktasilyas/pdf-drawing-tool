import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/models/models.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/starnote_nav_button.dart';
import 'package:drawing_ui/src/toolbar/tool_groups.dart';
import 'package:drawing_ui/src/toolbar/top_nav_menus.dart';
import 'package:drawing_ui/src/widgets/document_title_button.dart';

/// Top navigation bar (Row 1) — Navigation and document actions.
///
/// Layout (full):
/// ```
/// [Home] [Sidebar] [Title ▼]  ···spacer···  [Reader] [Grid] [Export] [More]
/// ```
///
/// Layout (compact / phone):
/// ```
/// [Home] [Title ▼]  ···spacer···  [Export] [More]
/// ```
class TopNavigationBar extends ConsumerWidget {
  const TopNavigationBar({
    super.key,
    this.documentTitle,
    this.onHomePressed,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
    this.compact = false,
    this.onAIPressed,
    this.onToolPanelRequested,
  });

  /// Document title to display.
  final String? documentTitle;

  /// Callback when home button is pressed.
  final VoidCallback? onHomePressed;

  /// Callback when rename is requested from title popover.
  final VoidCallback? onRenameDocument;

  /// Callback when delete is requested from title popover.
  final VoidCallback? onDeleteDocument;

  /// Callback when sidebar toggle is pressed.
  final VoidCallback? onSidebarToggle;

  /// Whether the sidebar is currently open.
  final bool isSidebarOpen;

  /// Whether to use compact mode (phone) — minimal buttons.
  final bool compact;

  /// Callback when AI button is pressed (shown in compact mode).
  final VoidCallback? onAIPressed;

  /// Callback when a tool's panel should open (shown in compact mode).
  final ValueChanged<ToolType>? onToolPanelRequested;

  /// Tools shown in the compact top bar (removed from bottom bar).
  static const List<ToolType> compactTopBarTools = [
    ToolType.laserPointer,
    ToolType.shapes,
    ToolType.text,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isReaderMode = ref.watch(readerModeProvider);
    final topPadding = compact ? MediaQuery.of(context).padding.top : 0.0;

    return Container(
      height: 48 + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: compact
            ? _buildCompactLayout(context, ref, colorScheme, isReaderMode)
            : _buildFullLayout(context, ref, colorScheme, isReaderMode),
      ),
    );
  }

  /// Compact layout (phone <600px) — all buttons evenly distributed:
  /// ```
  /// [Home] [AI] [Laser] [Shapes] [Text] [Mic] [Ruler] [Reader] [More]
  /// ```
  /// Title, Add Page and Export are consolidated into the "More" popup.
  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isReaderMode,
  ) {
    const double sz = 32;
    final currentTool = ref.watch(currentToolProvider);
    final rulerVisible = ref.watch(rulerVisibleProvider);

    final pageCount = ref.watch(pageCountProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StarNoteNavButton(
          icon: StarNoteIcons.home,
          tooltip: 'Ana Sayfa',
          onPressed: onHomePressed ?? () {},
          size: sz,
        ),
        if (pageCount > 1)
          StarNoteNavButton(
            icon: isSidebarOpen
                ? StarNoteIcons.sidebarActive
                : StarNoteIcons.sidebar,
            tooltip: 'Sayfa Paneli',
            onPressed: onSidebarToggle ?? () {},
            isActive: isSidebarOpen,
            size: sz,
          ),
        if (!isReaderMode) ...[
          if (onAIPressed != null)
            StarNoteNavButton(
              icon: StarNoteIcons.sparkle,
              tooltip: 'Yapay Zeka',
              onPressed: onAIPressed!,
              size: sz,
            ),
          ...compactTopBarTools.map((tool) => _buildCompactToolButton(
            ref: ref, tool: tool, currentTool: currentTool, size: sz,
          )),
          StarNoteNavButton(
            icon: StarNoteIcons.microphone,
            tooltip: 'Ses Kaydi',
            onPressed: () => showAudioMenu(
              context, ref, onSidebarToggle, isSidebarOpen),
            size: sz,
          ),
          StarNoteNavButton(
            icon: rulerVisible
                ? StarNoteIcons.rulerActive
                : StarNoteIcons.ruler,
            tooltip: 'Cetvel',
            onPressed: () => ref
                .read(rulerVisibleProvider.notifier)
                .state = !rulerVisible,
            isActive: rulerVisible,
            size: sz,
          ),
        ],
        if (isReaderMode) _buildReaderBadge(colorScheme),
        StarNoteNavButton(
          icon: isReaderMode
              ? StarNoteIcons.readerModeActive
              : StarNoteIcons.readerMode,
          tooltip: isReaderMode ? 'Duzenleme Modu' : 'Okuyucu Modu',
          onPressed: () {
            ref.read(readerModeProvider.notifier).state = !isReaderMode;
          },
          isActive: isReaderMode,
          size: sz,
        ),
        StarNoteNavButton(
          icon: StarNoteIcons.more,
          tooltip: 'Daha Fazla',
          onPressed: () => showMoreMenu(
            context, ref,
            documentTitle: documentTitle,
            onRenameDocument: onRenameDocument,
            onDeleteDocument: onDeleteDocument,
            showAddPage: !isReaderMode,
            showExport: true,
            compact: true,
          ),
          size: sz,
        ),
      ],
    );
  }

  /// Builds a tool button for the compact top bar.
  Widget _buildCompactToolButton({
    required WidgetRef ref,
    required ToolType tool,
    required ToolType currentTool,
    required double size,
  }) {
    final isSelected = tool == currentTool;
    return StarNoteNavButton(
      icon: StarNoteIcons.iconForTool(tool, active: isSelected),
      tooltip: tool.displayName,
      onPressed: () {
        if (isSelected && toolsWithPanel.contains(tool)) {
          onToolPanelRequested?.call(tool);
        } else {
          ref.read(currentToolProvider.notifier).selectTool(tool);
          ref.read(activePanelProvider.notifier).state = null;
        }
      },
      isActive: isSelected,
      size: size,
    );
  }

  /// Full layout (tablet/desktop >=600px): all buttons visible.
  Widget _buildFullLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isReaderMode,
  ) {
    final pageCount = ref.watch(pageCountProvider);

    return Row(
      children: [
        // -- Left: Home + Sidebar + Title --
        StarNoteNavButton(
          icon: StarNoteIcons.home,
          tooltip: 'Ana Sayfa',
          onPressed: onHomePressed ?? () {},
        ),

        if (pageCount > 1)
          StarNoteNavButton(
            icon: isSidebarOpen
                ? StarNoteIcons.sidebarActive
                : StarNoteIcons.sidebar,
            tooltip: 'Sayfa Paneli',
            onPressed: onSidebarToggle ?? () {},
            isActive: isSidebarOpen,
          ),

        const SizedBox(width: 4),
        Flexible(
          child: DocumentTitleButton(
            title: documentTitle,
            onRename: onRenameDocument ?? () {},
            onDelete: onDeleteDocument ?? () {},
            maxWidth: 300,
          ),
        ),

        if (isReaderMode) ...[
          const SizedBox(width: 8),
          _buildReaderBadge(colorScheme),
        ],

        // -- Center spacer --
        const Expanded(child: SizedBox()),

        // -- Right: Reader + Add Page + Export + More --
        StarNoteNavButton(
          icon: isReaderMode
              ? StarNoteIcons.readerModeActive
              : StarNoteIcons.readerMode,
          tooltip: isReaderMode ? 'Duzenleme Modu' : 'Okuyucu Modu',
          onPressed: () {
            ref.read(readerModeProvider.notifier).state = !isReaderMode;
          },
          isActive: isReaderMode,
        ),

        if (!isReaderMode)
          StarNoteNavButton(
            icon: StarNoteIcons.pageAdd,
            tooltip: 'Sayfa Ekle',
            onPressed: () => showAddPageMenu(context),
          ),

        if (!isReaderMode)
          StarNoteNavButton(
            icon: StarNoteIcons.microphone,
            tooltip: 'Ses Kaydi',
            onPressed: () => showAudioMenu(
              context, ref, onSidebarToggle, isSidebarOpen),
          ),

        StarNoteNavButton(
          icon: StarNoteIcons.exportIcon,
          tooltip: 'Dışa Aktar',
          onPressed: () => showExportMenu(context, ref),
        ),

        StarNoteNavButton(
          icon: StarNoteIcons.more,
          tooltip: 'Daha Fazla',
          onPressed: () => showMoreMenu(context, ref),
        ),
      ],
    );
  }

  /// "Salt okunur" badge shown in reader mode.
  Widget _buildReaderBadge(ColorScheme colorScheme) {
    return Semantics(
      label: 'Salt okunur mod aktif',
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            StarNoteIcons.readerMode,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Salt okunur',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    ),
    );
  }

}
