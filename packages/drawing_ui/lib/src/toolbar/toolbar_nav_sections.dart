import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/starnote_nav_button.dart';

/// Left navigation section: Home, Sidebar toggle, document title, reader badge.
///
/// Pure widget — all state is passed in via parameters.
class ToolbarNavLeft extends StatelessWidget {
  const ToolbarNavLeft({
    super.key,
    this.documentTitle,
    this.onHomePressed,
    this.onTitlePressed,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
    this.isReaderMode = false,
    this.pageCount = 1,
  });

  final String? documentTitle;
  final VoidCallback? onHomePressed;
  final VoidCallback? onTitlePressed;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;
  final bool isReaderMode;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        _DocumentTitle(
          title: documentTitle,
          onPressed: onTitlePressed,
          colorScheme: colorScheme,
        ),
        if (isReaderMode) ...[
          const SizedBox(width: 8),
          _ReaderBadge(colorScheme: colorScheme),
        ],
      ],
    );
  }
}

/// Right navigation section: Reader toggle, Grid toggle, Export, More.
///
/// Pure widget — all actions are via callbacks, no provider dependency.
class ToolbarNavRight extends StatelessWidget {
  const ToolbarNavRight({
    super.key,
    this.isReaderMode = false,
    this.gridVisible = true,
    this.onReaderToggle,
    this.onGridToggle,
    this.onExportPressed,
    this.onMorePressed,
  });

  final bool isReaderMode;
  final bool gridVisible;
  final VoidCallback? onReaderToggle;
  final VoidCallback? onGridToggle;
  final VoidCallback? onExportPressed;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarNoteNavButton(
          icon: isReaderMode
              ? StarNoteIcons.readerModeActive
              : StarNoteIcons.readerMode,
          tooltip: isReaderMode ? 'Duzenleme Modu' : 'Okuyucu Modu',
          onPressed: onReaderToggle ?? () {},
          isActive: isReaderMode,
        ),
        if (!isReaderMode)
          StarNoteNavButton(
            icon: gridVisible ? StarNoteIcons.gridOn : StarNoteIcons.gridOff,
            tooltip: gridVisible ? 'Kilavuzu Gizle' : 'Kilavuzu Goster',
            onPressed: onGridToggle ?? () {},
            isActive: gridVisible,
          ),
        StarNoteNavButton(
          icon: StarNoteIcons.exportIcon,
          tooltip: 'Disa Aktar',
          onPressed: onExportPressed ?? () {},
        ),
        StarNoteNavButton(
          icon: StarNoteIcons.more,
          tooltip: 'Daha Fazla',
          onPressed: onMorePressed ?? () {},
        ),
      ],
    );
  }
}

/// Document title pill with caret-down icon.
class _DocumentTitle extends StatelessWidget {
  const _DocumentTitle({
    required this.title,
    required this.onPressed,
    required this.colorScheme,
  });

  final String? title;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Doküman Seçenekleri',
      child: Semantics(
        label: title ?? 'İsimsiz Not',
        button: true,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title ?? 'İsimsiz Not',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 3),
                PhosphorIcon(
                  StarNoteIcons.caretDown,
                  size: 12,
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

/// "Salt okunur" badge shown in reader mode.
class _ReaderBadge extends StatelessWidget {
  const _ReaderBadge({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Salt okunur mod aktif',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              StarNoteIcons.readerMode,
              size: 12,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 3),
            Text(
              'Salt okunur',
              style: TextStyle(
                fontSize: 11,
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
