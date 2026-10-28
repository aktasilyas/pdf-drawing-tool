/// Export options panel shown as a popover below the export toolbar button.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/export_options.dart';
import 'package:drawing_ui/src/panels/export_options_section.dart';
import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/panels/pdf_export_action.dart';
import 'package:drawing_ui/src/panels/png_export_action.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

export 'package:drawing_ui/src/panels/pdf_export_action.dart';

/// Export panel with PDF and PNG export options.
class ExportPanel extends ConsumerStatefulWidget {
  const ExportPanel({
    super.key,
    required this.onClose,
    this.embedded = false,
    this.initialOptions = const ExportOptions(),
  });

  final VoidCallback onClose;
  final bool embedded;

  /// Options the panel opens with (goldens render the range state).
  @visibleForTesting
  final ExportOptions initialOptions;

  @override
  ConsumerState<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends ConsumerState<ExportPanel> {
  late ExportOptions _options = widget.initialOptions;

  VoidCallback get onClose => widget.onClose;

  @override
  Widget build(BuildContext context) {
    final embedded = widget.embedded;
    final pageCount = ref.watch(pageCountProvider);
    final valid = _options.isValid(pageCount);
    final cs = Theme.of(context).colorScheme;
    final isInfinite = ref.watch(isInfiniteCanvasProvider);
    final s = context.drawingStrings.export;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PanelHeader(cs: cs),
        if (!isInfinite)
          ExportOptionsSection(
            options: _options,
            pageCount: pageCount,
            onChanged: (o) => setState(() => _options = o),
          ),
        if (isInfinite)
          PageOptionsMenuItem(
            icon: ElyanotesIcons.image,
            label: s.exportPng,
            onTap: () => _exportPNG(context, ref),
          )
        else
          PageOptionsMenuItem(
            icon: ElyanotesIcons.pdfFile,
            label: s.exportPdf,
            onTap: valid ? () => _exportPDF(context, ref) : null,
          ),
        if (!isInfinite)
          PageOptionsMenuItem(
            icon: ElyanotesIcons.share,
            label: s.sharePdf,
            onTap: valid ? () => _exportPDF(context, ref, share: true) : null,
          ),
      ],
    );

    if (!embedded) {
      content = Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 260, child: content),
      );
    }
    return content;
  }

  void _exportPDF(BuildContext context, WidgetRef ref, {bool share = false}) {
    final strings = context.drawingStrings.export;
    onClose();
    final document = ref.read(documentProvider);
    final notifier = ref.read(exportProgressProvider.notifier);
    final watermark = ref.read(exportWatermarkProvider);
    final runner = ref.read(pdfExportRunnerProvider);
    final currentIndex = ref.read(currentPageIndexProvider);
    runner.run(
      notifier,
      document,
      strings: strings,
      addWatermark: watermark,
      share: share,
      options: _options,
      currentPageIndex: currentIndex,
    );
  }

  /// Renders the current page off-screen and saves it as PNG.
  void _exportPNG(BuildContext context, WidgetRef ref) {
    final strings = context.drawingStrings.export;
    onClose();
    exportCurrentPageAsPNG(ref, strings: strings);
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(context.drawingStrings.toolbar.export,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ),
    );
  }
}
