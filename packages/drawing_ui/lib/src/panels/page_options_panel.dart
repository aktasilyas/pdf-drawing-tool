import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

import 'page_options_actions.dart';
import 'page_options_template_actions.dart';
import 'page_options_widgets.dart';
import 'toolbar_settings_panel.dart';

/// GoodNotes-style page options popup panel.
class PageOptionsPanel extends ConsumerStatefulWidget {
  const PageOptionsPanel({
    super.key,
    required this.onClose,
    this.embedded = false,
    this.pageIndex,
    this.documentTitle,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onAddPage,
    this.onExport,
    this.compact = false,
  });

  final VoidCallback onClose;

  /// When true, skips Material/SizedBox wrapper (used inside PopoverController).
  final bool embedded;

  /// When set, operates on this specific page index instead of
  /// [currentPageIndexProvider]. Used by the sidebar "..." button.
  final int? pageIndex;

  /// Document title shown at top of panel (used by MediumToolbar).
  final String? documentTitle;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;

  /// Callback to open the Add Page panel (used when the button is hidden).
  final VoidCallback? onAddPage;

  /// Callback to open the Export panel (used when the button is hidden).
  final VoidCallback? onExport;

  /// When true, uses smaller spacing/fonts (MediumToolbar popup).
  final bool compact;

  @override
  ConsumerState<PageOptionsPanel> createState() => _PageOptionsPanelState();
}

class _PageOptionsPanelState extends ConsumerState<PageOptionsPanel>
    with PageOptionsActions, PageOptionsTemplateActions {
  @override
  VoidCallback get onPanelClose => widget.onClose;

  /// Resolved page index: either the explicit [pageIndex] or current.
  @override
  int get targetPageIndex =>
      widget.pageIndex ?? ref.read(currentPageIndexProvider);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final int pageIndex =
        widget.pageIndex ?? ref.watch(currentPageIndexProvider);
    final pageCount = ref.watch(pageCountProvider);
    final doc = ref.watch(documentProvider);
    final isBookmarked = doc.pages[pageIndex].isBookmarked;
    final hasCopiedPage = ref.watch(copiedPageProvider) != null;

    final c = widget.compact;
    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.documentTitle != null) ...[
            PageOptionsHeader(title: widget.documentTitle!, compact: c),
            pageOptionsDivider(cs, compact: c),
            PageOptionsMenuItem(
              icon: ElyanotesIcons.editPencil,
              label: 'Yeniden Adlandır',
              compact: c,
              onTap: () {
                widget.onClose();
                widget.onRenameDocument?.call();
              },
            ),
            PageOptionsMenuItem(
              icon: ElyanotesIcons.trash,
              label: 'Çöpe Taşı',
              isDestructive: true,
              compact: c,
              onTap: () {
                widget.onClose();
                widget.onDeleteDocument?.call();
              },
            ),
            if (widget.onExport != null)
              PageOptionsMenuItem(
                icon: ElyanotesIcons.exportIcon,
                label: 'Dışa Aktar',
                compact: c,
                onTap: widget.onExport,
              ),
            pageOptionsThickDivider(cs, compact: c),
          ],
          PageOptionsHeader(title: 'Sayfa ${pageIndex + 1}', compact: c),
          pageOptionsDivider(cs, compact: c),
          if (widget.onAddPage != null)
            PageOptionsMenuItem(
              icon: ElyanotesIcons.pageAdd,
              label: 'Sayfa Ekle',
              compact: c,
              onTap: widget.onAddPage,
            ),
          PageOptionsMenuItem(
            icon: isBookmarked
                ? ElyanotesIcons.bookmarkFilled
                : ElyanotesIcons.bookmark,
            label: isBookmarked ? 'Yer imini kaldır' : 'Yer imi koy',
            compact: c,
            onTap: toggleBookmark,
          ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.copy,
            label: 'Sayfayı kopyala',
            compact: c,
            onTap: () => copyPage(context),
          ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.paste,
            label: 'Sayfayı yapıştır',
            compact: c,
            onTap: hasCopiedPage ? () => pastePage(context) : null,
          ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.duplicate,
            label: 'Sayfayı çoğalt',
            compact: c,
            onTap: () => duplicatePage(context),
          ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.template,
            label: 'Şablonu değiştir',
            compact: c,
            onTap: () => changeTemplate(context),
          ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.goToPage,
            label: 'Sayfaya git',
            compact: c,
            trailing: pageOptionsChevronTrailing(cs,
                '${pageIndex + 1} / $pageCount', Theme.of(context).textTheme),
            onTap: () => showGoToPage(context),
          ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.pdfFile,
            label: 'PDF olarak dışa aktar',
            compact: c,
            onTap: exportPageAsPdf,
          ),
          pageOptionsDivider(cs, compact: c),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.pageClear,
            label: 'Sayfayı temizle',
            isDestructive: true,
            compact: c,
            onTap: () => clearPage(context),
          ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.trash,
            label: 'Çöpe taşı',
            isDestructive: true,
            compact: c,
            onTap: () => deletePage(context),
          ),
          pageOptionsThickDivider(cs, compact: c),
          PageOptionsSectionHeader(title: 'Ayarlar', compact: c),
          ScrollDirectionItem(onClose: widget.onClose, compact: c),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.sliders,
            label: 'Araç Çubuğunu Düzenle',
            compact: c,
            onTap: () {
              widget.onClose();
              showDialog<void>(
                context: context,
                builder: (_) => const Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ToolbarSettingsPanel(),
                ),
              );
            },
          ),
          SizedBox(height: c ? 4 : 8),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: cs.shadow.withValues(alpha: 0.26),
      child: SizedBox(width: 320, child: content),
    );
  }
}
