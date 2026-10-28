import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/elyanotes_nav_button.dart';
import 'package:drawing_ui/src/toolbar/top_nav_menus.dart';

/// Phone navigation row (Row 1 of the phone chrome, < 600dp), see
/// docs/specs/52-editor-chrome.md, section 3:
/// ```
/// [Back] Serif title ......... [Pages] [Ruler] [Mic] [Reader] [More]
/// ```
/// 48dp tall, no capsule: it sits directly on the desk band (`background`).
/// Title rename/delete, Add page and Export live in the More sheet. Ruler
/// and Mic follow the same rules as the tablet actions capsule; Reader stays
/// visible so reader mode can always be left.
class PhoneNavRow extends ConsumerWidget {
  const PhoneNavRow({
    super.key,
    this.documentTitle,
    this.onHomePressed,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.onSidebarToggle,
    this.isSidebarOpen = false,
  });

  /// Row height (one 48dp touch target).
  static const double height = ChromeSizes.minTouchTarget;

  final String? documentTitle;
  final VoidCallback? onHomePressed;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.drawingStrings.toolbar;
    final title = documentTitle ?? '';
    final isReaderMode = ref.watch(readerModeProvider);
    final isInfinite = ref.watch(isInfiniteCanvasProvider);
    final pageCount = ref.watch(pageCountProvider);
    final rulerVisible = ref.watch(rulerVisibleProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final rulerEnabled = toolbarConfig.extraToolVisible('ruler');
    final audioEnabled = toolbarConfig.extraToolVisible('audio') &&
        ref.watch(audioRecordingEnabledProvider);

    return SizedBox(
      height: height,
      child: Row(
        children: [
          ElyanotesNavButton(
            icon: ElyanotesIcons.home,
            tooltip: s.home,
            onPressed: onHomePressed ?? () {},
          ),
          const SizedBox(width: ChromeSpacing.xs),
          Expanded(child: _Title(title.isEmpty ? s.untitled : title)),
          if (pageCount > 1)
            ElyanotesNavButton(
              icon: isSidebarOpen
                  ? ElyanotesIcons.sidebarActive
                  : ElyanotesIcons.sidebar,
              tooltip: s.pages,
              onPressed: onSidebarToggle ?? () {},
              isActive: isSidebarOpen,
            ),
          if (!isReaderMode && rulerEnabled)
            ElyanotesNavButton(
              icon: rulerVisible
                  ? ElyanotesIcons.rulerActive
                  : ElyanotesIcons.ruler,
              tooltip: s.ruler,
              onPressed: () =>
                  ref.read(rulerVisibleProvider.notifier).state = !rulerVisible,
              isActive: rulerVisible,
            ),
          if (!isReaderMode && !isInfinite && audioEnabled)
            ElyanotesNavButton(
              icon: ElyanotesIcons.microphone,
              tooltip: s.audio,
              onPressed: () =>
                  showAudioMenu(context, ref, onSidebarToggle, isSidebarOpen),
            ),
          ElyanotesNavButton(
            icon: isReaderMode
                ? ElyanotesIcons.readerModeActive
                : ElyanotesIcons.readerMode,
            tooltip: isReaderMode ? s.editMode : s.readerMode,
            onPressed: () =>
                ref.read(readerModeProvider.notifier).state = !isReaderMode,
            isActive: isReaderMode,
          ),
          ElyanotesNavButton(
            icon: ElyanotesIcons.more,
            tooltip: s.more,
            onPressed: () => isInfinite
                ? showInfiniteBackgroundMenu(context)
                : showMoreMenu(
                    context,
                    ref,
                    documentTitle: documentTitle,
                    onRenameDocument: onRenameDocument,
                    onDeleteDocument: onDeleteDocument,
                    showAddPage: !isReaderMode,
                    showExport: true,
                    compact: true,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Serif document title: titleMedium in the titleLarge (serif) family,
/// letter-spacing -0.5% (spec section 6).
class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final base = textTheme.titleMedium ?? const TextStyle();
    final fontSize = base.fontSize ?? 16;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(
        fontFamily: textTheme.titleLarge?.fontFamily,
        letterSpacing: -0.005 * fontSize,
        color: ChromePalette.of(context).textPrimary,
      ),
    );
  }
}
