import 'package:flutter/material.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/elyanotes_nav_button.dart';
import 'package:drawing_ui/src/toolbar/toolbar_reader_badge.dart';
import 'package:drawing_ui/src/widgets/document_title_button.dart';

/// Left navigation section: Home, Sidebar toggle, document title, reader badge.
class ToolbarNavLeft extends StatelessWidget {
  const ToolbarNavLeft({
    super.key,
    this.documentTitle,
    this.onHomePressed,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
    this.isReaderMode = false,
    this.pageCount = 1,
    this.showTitle = true,
    this.titleMaxWidth = 160,
    this.showReaderBadge = true,
  });

  final String? documentTitle;
  final VoidCallback? onHomePressed;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;
  final bool isReaderMode;
  final int pageCount;

  /// When false, hides the title (MediumToolbar moves it to "more").
  final bool showTitle;

  /// Maximum width of the document title pill.
  final double titleMaxWidth;

  /// Whether reader mode shows the read-only badge.
  final bool showReaderBadge;

  @override
  Widget build(BuildContext context) {
    final s = context.drawingStrings.toolbar;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElyanotesNavButton(
          icon: ElyanotesIcons.home,
          tooltip: s.home,
          onPressed: onHomePressed ?? () {},
        ),
        if (pageCount > 1)
          ElyanotesNavButton(
            icon: isSidebarOpen
                ? ElyanotesIcons.sidebarActive
                : ElyanotesIcons.sidebar,
            tooltip: s.pages,
            onPressed: onSidebarToggle ?? () {},
            isActive: isSidebarOpen,
          ),
        if (showTitle) ...[
          const SizedBox(width: ChromeSpacing.xs),
          DocumentTitleButton(
            title: documentTitle,
            onRename: onRenameDocument ?? () {},
            onDelete: onDeleteDocument ?? () {},
            maxWidth: titleMaxWidth,
          ),
        ],
        if (isReaderMode && showReaderBadge) ...[
          const SizedBox(width: ChromeSpacing.sm),
          const ToolbarReaderBadge(),
        ],
      ],
    );
  }
}
