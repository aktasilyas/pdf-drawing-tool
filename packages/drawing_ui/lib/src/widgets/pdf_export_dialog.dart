/// Dialog for PDF export options.
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';

/// Configuration for PDF export.
class PDFExportConfig {
  final PDFExportMode exportMode;
  final PDFExportQuality quality;
  final bool includeBackground;
  final PDFPageFormat? pageFormat;

  const PDFExportConfig({
    this.exportMode = PDFExportMode.vector,
    this.quality = PDFExportQuality.high,
    this.includeBackground = true,
    this.pageFormat,
  });

  PDFExportOptions toExportOptions() {
    return PDFExportOptions(
      exportMode: exportMode,
      quality: quality,
      includeBackground: includeBackground,
      pageFormat: pageFormat,
    );
  }
}

/// Result of export dialog.
class ExportDialogResult {
  final bool confirmed;
  final PDFExportConfig? config;

  const ExportDialogResult({required this.confirmed, this.config});

  factory ExportDialogResult.success({required PDFExportConfig config}) =>
      ExportDialogResult(confirmed: true, config: config);

  factory ExportDialogResult.cancelled() =>
      const ExportDialogResult(confirmed: false);
}

/// Dialog for PDF export options — compact, scrollable, Turkish UI.
class PDFExportDialog extends StatefulWidget {
  const PDFExportDialog({
    super.key,
    required this.totalPages,
    this.onExport,
  });

  final int totalPages;
  final void Function(PDFExportConfig config)? onExport;

  @override
  State<PDFExportDialog> createState() => _PDFExportDialogState();
}

class _PDFExportDialogState extends State<PDFExportDialog> {
  PDFExportMode _exportMode = PDFExportMode.vector;
  PDFExportQuality _quality = PDFExportQuality.high;
  PDFPageFormat _pageFormat = PDFPageFormat.a4;
  bool _includeBackground = true;

  void _handleExport() {
    final config = PDFExportConfig(
      exportMode: _exportMode,
      quality: _quality,
      includeBackground: _includeBackground,
      pageFormat: _pageFormat,
    );
    widget.onExport?.call(config);
    Navigator.of(context).pop(ExportDialogResult.success(config: config));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(cs),
              const SizedBox(height: 16),
              _buildModeSection(cs),
              const SizedBox(height: 14),
              _buildQualitySection(cs),
              const SizedBox(height: 14),
              _buildFormatSection(cs),
              const SizedBox(height: 14),
              _buildBackgroundToggle(cs),
              const SizedBox(height: 20),
              _buildActions(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PDF Olarak Dışa Aktar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: cs.onSurface)),
        const SizedBox(height: 2),
        Text('${widget.totalPages} sayfa',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildModeSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Dışa Aktarma Modu', cs),
        const SizedBox(height: 6),
        Row(children: [
          _modeCard('Vektör', PDFExportMode.vector, cs),
          const SizedBox(width: 8),
          _modeCard('Raster', PDFExportMode.raster, cs),
          const SizedBox(width: 8),
          _modeCard('Karma', PDFExportMode.hybrid, cs),
        ]),
      ],
    );
  }

  Widget _modeCard(String label, PDFExportMode mode, ColorScheme cs) {
    final selected = _exportMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _exportMode = mode),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? cs.onPrimaryContainer : cs.onSurface)),
        ),
      ),
    );
  }

  Widget _buildQualitySection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Kalite', cs),
        const SizedBox(height: 6),
        Row(children: [
          _qualityCard('Düşük', '72', PDFExportQuality.low, cs),
          const SizedBox(width: 6),
          _qualityCard('Orta', '150', PDFExportQuality.medium, cs),
          const SizedBox(width: 6),
          _qualityCard('Yüksek', '300', PDFExportQuality.high, cs),
          const SizedBox(width: 6),
          _qualityCard('Baskı', '600', PDFExportQuality.print, cs),
        ]),
      ],
    );
  }

  Widget _qualityCard(String label, String dpi, PDFExportQuality q,
      ColorScheme cs) {
    final selected = _quality == q;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _quality = q),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant, width: 1),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? cs.onPrimaryContainer : cs.onSurface)),
            Text('$dpi DPI', style: TextStyle(fontSize: 9,
                color: selected
                    ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                    : cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormatSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Sayfa Formatı', cs),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PDFPageFormat>(
              value: _pageFormat,
              isExpanded: true,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              items: const [
                DropdownMenuItem(value: PDFPageFormat.a4, child: Text('A4')),
                DropdownMenuItem(value: PDFPageFormat.a5, child: Text('A5')),
                DropdownMenuItem(
                    value: PDFPageFormat.letter, child: Text('Letter')),
                DropdownMenuItem(
                    value: PDFPageFormat.legal, child: Text('Legal')),
              ],
              onChanged: (f) { if (f != null) setState(() => _pageFormat = f); },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundToggle(ColorScheme cs) {
    return Row(children: [
      Expanded(child: Text('Arka planı dahil et',
          style: TextStyle(fontSize: 13, color: cs.onSurface))),
      Switch(
        value: _includeBackground,
        onChanged: (v) => setState(() => _includeBackground = v),
      ),
    ]);
  }

  Widget _buildActions(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(ExportDialogResult.cancelled()),
          child: Text('İptal',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _handleExport,
          child: const Text('Dışa Aktar'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, ColorScheme cs) {
    return Text(text, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface));
  }
}
