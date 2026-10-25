import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/elyanotes_nav_button.dart';
import 'package:drawing_ui/src/toolbar/phone_nav_row.dart';
import 'package:drawing_ui/src/toolbar/top_nav_menus.dart';
import 'package:drawing_ui/src/widgets/document_title_button.dart';

/// Top navigation bar (Row 1) — Navigation and document actions.
///
/// Layout (full):
/// ```
/// [Home] [Sidebar] [Title ▼]  ···spacer···  [Reader] [Grid] [Export] [More]
/// ```
///
/// Compact (phone) renders a [PhoneNavRow] instead.
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

  /// Whether to use compact mode (phone): renders a [PhoneNavRow] on the
  /// desk band instead of the legacy full row.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) return _buildPhone(context);

    final colorScheme = Theme.of(context).colorScheme;
    final drawingTheme = DrawingTheme.of(context);
    final isReaderMode = ref.watch(readerModeProvider);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: drawingTheme.toolbarBackground,
        border: Border(
          bottom: BorderSide(
            color: drawingTheme.toolbarIconColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _buildFullLayout(context, ref, colorScheme, isReaderMode),
      ),
    );
  }

  /// Phone row 1 on the desk band, below the status-bar inset
  /// (docs/specs/52-editor-chrome.md, section 3).
  Widget _buildPhone(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      height: PhoneNavRow.height + topInset,
      color: ChromePalette.of(context).background,
      padding: EdgeInsets.fromLTRB(
        ChromeSpacing.xs,
        topInset,
        ChromeSpacing.xs,
        0,
      ),
      child: PhoneNavRow(
        documentTitle: documentTitle,
        onHomePressed: onHomePressed,
        onRenameDocument: onRenameDocument,
        onDeleteDocument: onDeleteDocument,
        onSidebarToggle: onSidebarToggle,
        isSidebarOpen: isSidebarOpen,
      ),
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
        ElyanotesNavButton(
          icon: ElyanotesIcons.home,
          tooltip: 'Ana Sayfa',
          onPressed: onHomePressed ?? () {},
        ),

        if (pageCount > 1)
          ElyanotesNavButton(
            icon: isSidebarOpen
                ? ElyanotesIcons.sidebarActive
                : ElyanotesIcons.sidebar,
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
        ElyanotesNavButton(
          icon: isReaderMode
              ? ElyanotesIcons.readerModeActive
              : ElyanotesIcons.readerMode,
          tooltip: isReaderMode ? 'Duzenleme Modu' : 'Okuyucu Modu',
          onPressed: () {
            ref.read(readerModeProvider.notifier).state = !isReaderMode;
          },
          isActive: isReaderMode,
        ),

        if (!isReaderMode && !ref.watch(isInfiniteCanvasProvider))
          ElyanotesNavButton(
            icon: ElyanotesIcons.pageAdd,
            tooltip: 'Sayfa Ekle',
            onPressed: () => showAddPageMenu(context),
          ),

        if (!isReaderMode &&
            !ref.watch(isInfiniteCanvasProvider) &&
            ref.watch(audioRecordingEnabledProvider))
          ElyanotesNavButton(
            icon: ElyanotesIcons.microphone,
            tooltip: 'Ses Kaydi',
            onPressed: () =>
                showAudioMenu(context, ref, onSidebarToggle, isSidebarOpen),
          ),

        ElyanotesNavButton(
          icon: ElyanotesIcons.exportIcon,
          tooltip: 'Dışa Aktar',
          onPressed: () => showExportMenu(context, ref),
        ),

        ElyanotesNavButton(
          icon: ElyanotesIcons.more,
          tooltip: 'Daha Fazla',
          onPressed: () => ref.read(isInfiniteCanvasProvider)
              ? showInfiniteBackgroundMenu(context)
              : showMoreMenu(context, ref),
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
              ElyanotesIcons.readerMode,
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
