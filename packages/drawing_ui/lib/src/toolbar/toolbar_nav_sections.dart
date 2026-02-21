import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/panels/add_page_panel.dart';
import 'package:drawing_ui/src/panels/audio_recording_dropdown.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/layers_list.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/starnote_nav_button.dart';
import 'package:drawing_ui/src/widgets/popover_panel.dart';

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

/// Which nav popover is currently open.
enum _NavPanel { addPage, audioRecording, layers, export, more }

/// Right navigation section: Reader toggle, Add Page, Export, More.
///
/// Uses [PopoverController] to show Add Page and More panels as popovers
/// with an arrow pointing to the anchor button (same style as tool panels).
class ToolbarNavRight extends ConsumerStatefulWidget {
  const ToolbarNavRight({
    super.key,
    this.isReaderMode = false,
    this.onReaderToggle,
    this.onShowRecordings,
  });

  final bool isReaderMode;
  final VoidCallback? onReaderToggle;
  final VoidCallback? onShowRecordings;

  @override
  ConsumerState<ToolbarNavRight> createState() => _ToolbarNavRightState();
}

class _ToolbarNavRightState extends ConsumerState<ToolbarNavRight> {
  final PopoverController _popover = PopoverController();
  final GlobalKey _addPageKey = GlobalKey();
  final GlobalKey _micKey = GlobalKey();
  final GlobalKey _layersKey = GlobalKey();
  final GlobalKey _exportKey = GlobalKey();
  final GlobalKey _moreKey = GlobalKey();
  _NavPanel? _activePanel;

  @override
  void didUpdateWidget(ToolbarNavRight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReaderMode && !oldWidget.isReaderMode) {
      _closePanel();
    }
  }

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  void _togglePanel(_NavPanel panel) {
    if (_activePanel == panel) {
      _closePanel();
      return;
    }
    setState(() => _activePanel = panel);
    final GlobalKey anchorKey;
    final Widget child;
    switch (panel) {
      case _NavPanel.addPage:
        anchorKey = _addPageKey;
        child = AddPagePanel(onClose: _closePanel, embedded: true);
      case _NavPanel.audioRecording:
        anchorKey = _micKey;
        child = AudioRecordingDropdown(
          onClose: _closePanel,
          onShowRecordings: () => widget.onShowRecordings?.call(),
        );
      case _NavPanel.layers:
        anchorKey = _layersKey;
        // Cap height to 60% of screen, min 280, max 420
        final screenH = MediaQuery.of(context).size.height;
        final layersH = (screenH * 0.6).clamp(280.0, 420.0);
        child = SizedBox(width: 260, height: layersH, child: const LayersList());
      case _NavPanel.export:
        anchorKey = _exportKey;
        child = ExportPanel(onClose: _closePanel, embedded: true);
      case _NavPanel.more:
        anchorKey = _moreKey;
        child = PageOptionsPanel(onClose: _closePanel, embedded: true);
    }
    _popover.show(
      context: context,
      anchorKey: anchorKey,
      maxWidth: 320,
      onDismiss: () {
        if (mounted) setState(() => _activePanel = null);
      },
      child: child,
    );
  }

  void _closePanel() {
    _popover.hide();
    if (mounted) setState(() => _activePanel = null);
  }

  @override
  Widget build(BuildContext context) {
    final rulerVisible = ref.watch(rulerVisibleProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarNoteNavButton(
          icon: widget.isReaderMode
              ? StarNoteIcons.readerModeActive
              : StarNoteIcons.readerMode,
          tooltip: widget.isReaderMode ? 'Duzenleme Modu' : 'Okuyucu Modu',
          onPressed: widget.onReaderToggle ?? () {},
          isActive: widget.isReaderMode,
        ),
        if (!widget.isReaderMode)
          StarNoteNavButton(
            icon: rulerVisible
                ? StarNoteIcons.rulerActive
                : StarNoteIcons.ruler,
            tooltip: 'Cetvel',
            onPressed: () => ref
                .read(rulerVisibleProvider.notifier)
                .state = !rulerVisible,
            isActive: rulerVisible,
          ),
        if (!widget.isReaderMode)
          StarNoteNavButton(
            key: _layersKey,
            icon: StarNoteIcons.layers,
            tooltip: 'Katmanlar',
            onPressed: () => _togglePanel(_NavPanel.layers),
            isActive: _activePanel == _NavPanel.layers,
          ),
        if (!widget.isReaderMode)
          StarNoteNavButton(
            key: _addPageKey,
            icon: StarNoteIcons.pageAdd,
            tooltip: 'Sayfa Ekle',
            onPressed: () => _togglePanel(_NavPanel.addPage),
            isActive: _activePanel == _NavPanel.addPage,
          ),
        if (!widget.isReaderMode)
          StarNoteNavButton(
            key: _micKey,
            icon: StarNoteIcons.microphone,
            tooltip: 'Ses Kaydi',
            onPressed: () => _togglePanel(_NavPanel.audioRecording),
            isActive: _activePanel == _NavPanel.audioRecording,
          ),
        StarNoteNavButton(
          key: _exportKey,
          icon: StarNoteIcons.exportIcon,
          tooltip: 'Dışa Aktar',
          onPressed: () => _togglePanel(_NavPanel.export),
          isActive: _activePanel == _NavPanel.export,
        ),
        StarNoteNavButton(
          key: _moreKey,
          icon: StarNoteIcons.more,
          tooltip: 'Daha Fazla',
          onPressed: () => _togglePanel(_NavPanel.more),
          isActive: _activePanel == _NavPanel.more,
        ),
      ],
    );
  }
}

/// Document title pill with caret-down icon.
class _DocumentTitle extends StatelessWidget {
  const _DocumentTitle({
    required this.title, required this.onPressed, required this.colorScheme,
  });
  final String? title;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final label = title ?? 'İsimsiz Not';
    return Tooltip(
      message: 'Doküman Seçenekleri',
      child: Semantics(
        label: label, button: true,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(label, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface))),
              const SizedBox(width: 3),
              PhosphorIcon(StarNoteIcons.caretDown, size: 12,
                  color: colorScheme.onSurfaceVariant),
            ]),
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
    final cs = colorScheme;
    return Semantics(
      label: 'Salt okunur mod aktif',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: cs.secondaryContainer, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          PhosphorIcon(StarNoteIcons.readerMode, size: 12,
              color: cs.onSecondaryContainer),
          const SizedBox(width: 3),
          Text('Salt okunur', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w500, color: cs.onSecondaryContainer)),
        ]),
      ),
    );
  }
}
