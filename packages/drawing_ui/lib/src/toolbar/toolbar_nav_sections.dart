import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/add_page_panel.dart';
import 'package:drawing_ui/src/panels/audio_recording_dropdown.dart';
import 'package:drawing_ui/src/panels/export_panel.dart';
import 'package:drawing_ui/src/panels/infinite_background_panel.dart';
import 'package:drawing_ui/src/panels/page_options_panel.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/layers_list.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/toolbar/elyanotes_nav_button.dart';
import 'package:drawing_ui/src/widgets/popover_panel.dart';

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
    this.documentTitle,
    this.onRenameDocument,
    this.onDeleteDocument,
    this.showAddPage = true,
    this.showExport = true,
  });

  final bool isReaderMode;
  final VoidCallback? onReaderToggle;
  final VoidCallback? onShowRecordings;

  /// Document title shown in the "more" popup (used by MediumToolbar).
  final String? documentTitle;
  final VoidCallback? onRenameDocument;
  final VoidCallback? onDeleteDocument;

  /// When false, hides the Add Page button (moved to "more" popup).
  final bool showAddPage;

  /// When false, hides the Export button (moved to "more" popup).
  final bool showExport;

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
        anchorKey = widget.showAddPage ? _addPageKey : _moreKey;
        child = AddPagePanel(onClose: _closePanel, embedded: true);
      case _NavPanel.audioRecording:
        anchorKey = _micKey;
        child = AudioRecordingDropdown(
          onClose: _closePanel,
          onShowRecordings: () => widget.onShowRecordings?.call(),
        );
      case _NavPanel.layers:
        anchorKey = _layersKey;
        final screenH = MediaQuery.of(context).size.height;
        final layersH = (screenH * 0.6).clamp(280.0, 420.0);
        child =
            SizedBox(width: 260, height: layersH, child: const LayersList());
      case _NavPanel.export:
        anchorKey = widget.showExport ? _exportKey : _moreKey;
        child = ExportPanel(onClose: _closePanel, embedded: true);
      case _NavPanel.more:
        anchorKey = _moreKey;
        if (ref.read(isInfiniteCanvasProvider)) {
          child = InfiniteBackgroundPanel(onClose: _closePanel);
        } else {
          final isCompact = !widget.showAddPage || !widget.showExport;
          child = PageOptionsPanel(
            onClose: _closePanel,
            embedded: true,
            compact: isCompact,
            documentTitle: widget.documentTitle,
            onRenameDocument: widget.onRenameDocument,
            onDeleteDocument: widget.onDeleteDocument,
            onAddPage: !widget.showAddPage
                ? () {
                    _closePanel();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _togglePanel(_NavPanel.addPage);
                    });
                  }
                : null,
            onExport: !widget.showExport
                ? () {
                    _closePanel();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _togglePanel(_NavPanel.export);
                    });
                  }
                : null,
          );
        }
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
    final s = context.drawingStrings.toolbar;
    final rulerVisible = ref.watch(rulerVisibleProvider);
    final toolbarConfig = ref.watch(toolbarConfigProvider);
    final rulerEnabled = toolbarConfig.extraToolVisible('ruler');
    final audioEnabled = toolbarConfig.extraToolVisible('audio') &&
        ref.watch(audioRecordingEnabledProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElyanotesNavButton(
          icon: widget.isReaderMode
              ? ElyanotesIcons.readerModeActive
              : ElyanotesIcons.readerMode,
          tooltip: widget.isReaderMode ? s.editMode : s.readerMode,
          onPressed: widget.onReaderToggle ?? () {},
          isActive: widget.isReaderMode,
        ),
        if (!widget.isReaderMode && rulerEnabled)
          ElyanotesNavButton(
            icon: rulerVisible
                ? ElyanotesIcons.rulerActive
                : ElyanotesIcons.ruler,
            tooltip: s.ruler,
            onPressed: () =>
                ref.read(rulerVisibleProvider.notifier).state = !rulerVisible,
            isActive: rulerVisible,
          ),
        if (!widget.isReaderMode && !ref.watch(isInfiniteCanvasProvider))
          ElyanotesNavButton(
            key: _layersKey,
            icon: ElyanotesIcons.layers,
            tooltip: s.layers,
            onPressed: () => _togglePanel(_NavPanel.layers),
            isActive: _activePanel == _NavPanel.layers,
          ),
        if (!widget.isReaderMode &&
            widget.showAddPage &&
            !ref.watch(isInfiniteCanvasProvider))
          ElyanotesNavButton(
            key: _addPageKey,
            icon: ElyanotesIcons.pageAdd,
            tooltip: s.addPage,
            onPressed: () => _togglePanel(_NavPanel.addPage),
            isActive: _activePanel == _NavPanel.addPage,
          ),
        if (!widget.isReaderMode &&
            audioEnabled &&
            !ref.watch(isInfiniteCanvasProvider))
          ElyanotesNavButton(
            key: _micKey,
            icon: ElyanotesIcons.microphone,
            tooltip: s.audio,
            onPressed: () => _togglePanel(_NavPanel.audioRecording),
            isActive: _activePanel == _NavPanel.audioRecording,
          ),
        if (widget.showExport)
          ElyanotesNavButton(
            key: _exportKey,
            icon: ElyanotesIcons.exportIcon,
            tooltip: s.export,
            onPressed: () => _togglePanel(_NavPanel.export),
            isActive: _activePanel == _NavPanel.export,
          ),
        ElyanotesNavButton(
          key: _moreKey,
          icon: ElyanotesIcons.more,
          tooltip: s.more,
          onPressed: () => _togglePanel(_NavPanel.more),
          isActive: _activePanel == _NavPanel.more,
        ),
      ],
    );
  }
}
