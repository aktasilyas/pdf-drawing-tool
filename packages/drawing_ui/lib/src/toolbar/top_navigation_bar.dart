import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/starnote_nav_button.dart';
import 'package:drawing_ui/src/toolbar/top_nav_menus.dart';

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
    this.onTitlePressed,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
    this.compact = false,
  });

  /// Document title to display.
  final String? documentTitle;

  /// Callback when home button is pressed.
  final VoidCallback? onHomePressed;

  /// Callback when document title is pressed.
  final VoidCallback? onTitlePressed;

  /// Callback when sidebar toggle is pressed.
  final VoidCallback? onSidebarToggle;

  /// Whether the sidebar is currently open.
  final bool isSidebarOpen;

  /// Whether to use compact mode (phone) — minimal buttons.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isReaderMode = ref.watch(readerModeProvider);

    return Container(
      height: 48,
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

  /// Compact layout (phone <600px): Home + Title + Export + More.
  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isReaderMode,
  ) {
    return Row(
      children: [
        StarNoteNavButton(
          icon: StarNoteIcons.home,
          tooltip: 'Ana Sayfa',
          onPressed: onHomePressed ?? () {},
        ),
        const SizedBox(width: 4),
        if (isReaderMode) _buildReaderBadge(colorScheme),
        if (isReaderMode) const SizedBox(width: 4),
        Expanded(child: _buildDocumentTitle(colorScheme)),
        const SizedBox(width: 4),
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
        StarNoteNavButton(
          icon: StarNoteIcons.exportIcon,
          tooltip: 'Disa Aktar',
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

  /// Full layout (tablet/desktop >=600px): all buttons visible.
  Widget _buildFullLayout(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    bool isReaderMode,
  ) {
    final gridVisible = ref.watch(gridVisibilityProvider);
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
        Flexible(child: _buildDocumentTitle(colorScheme)),

        if (isReaderMode) ...[
          const SizedBox(width: 8),
          _buildReaderBadge(colorScheme),
        ],

        // -- Center spacer --
        const Expanded(child: SizedBox()),

        // -- Right: Reader + Grid (hidden in reader mode) + Export + More --
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
            icon: gridVisible ? StarNoteIcons.gridOn : StarNoteIcons.gridOff,
            tooltip: gridVisible ? 'Kilavuzu Gizle' : 'Kilavuzu Goster',
            onPressed: () =>
                ref.read(gridVisibilityProvider.notifier).state = !gridVisible,
            isActive: gridVisible,
          ),

        StarNoteNavButton(
          icon: StarNoteIcons.exportIcon,
          tooltip: 'Disa Aktar',
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

  /// Document title pill with caret-down icon.
  Widget _buildDocumentTitle(ColorScheme colorScheme) {
    return Tooltip(
      message: 'Doküman Seçenekleri',
      child: Semantics(
        label: documentTitle ?? 'İsimsiz Not',
        button: true,
        child: GestureDetector(
          onTap: onTitlePressed,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    documentTitle ?? 'İsimsiz Not',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                PhosphorIcon(
                  StarNoteIcons.caretDown,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
