import 'package:flutter/material.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';

/// Configuration for PDF export.
class PDFExportConfig {
  /// Export mode.
  final PDFExportMode exportMode;

  /// Export quality.
  final PDFExportQuality quality;

  /// Whether to include backgrounds.
  final bool includeBackground;

  /// Page format.
  final PDFPageFormat? pageFormat;

  const PDFExportConfig({
    this.exportMode = PDFExportMode.vector,
    this.quality = PDFExportQuality.high,
    this.includeBackground = true,
    this.pageFormat,
  });

  /// Creates a copy with new values.
  PDFExportConfig copyWith({
    PDFExportMode? exportMode,
    PDFExportQuality? quality,
    bool? includeBackground,
    PDFPageFormat? pageFormat,
  }) {
    return PDFExportConfig(
      exportMode: exportMode ?? this.exportMode,
      quality: quality ?? this.quality,
      includeBackground: includeBackground ?? this.includeBackground,
      pageFormat: pageFormat ?? this.pageFormat,
    );
  }

  /// Converts to PDFExportOptions.
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
  /// Whether export was confirmed.
  final bool confirmed;

  /// Export configuration (null if cancelled).
  final PDFExportConfig? config;

  const ExportDialogResult({
    required this.confirmed,
    this.config,
  });

  /// Creates a successful result.
  factory ExportDialogResult.success({required PDFExportConfig config}) {
    return ExportDialogResult(
      confirmed: true,
      config: config,
    );
  }

  /// Creates a cancelled result.
  factory ExportDialogResult.cancelled() {
    return const ExportDialogResult(confirmed: false);
  }
}

/// Dialog for PDF export options.
class PDFExportDialog extends StatefulWidget {
  /// Total number of pages to export.
  final int totalPages;

  /// Whether export is in progress.
  final bool isExporting;

  /// Progress message during export.
  final String? progressMessage;

  /// Error message to display.
  final String? errorMessage;

  /// Callback when export is initiated.
  final void Function(PDFExportConfig config)? onExport;

  const PDFExportDialog({
    super.key,
    required this.totalPages,
    this.isExporting = false,
    this.progressMessage,
    this.errorMessage,
    this.onExport,
  });

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

  void _handleCancel() {
    if (widget.isExporting) return;
    Navigator.of(context).pop(ExportDialogResult.cancelled());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Export to PDF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.totalPages} pages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (widget.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Export mode
            ExportModeSelector(
              selectedMode: _exportMode,
              onModeChanged: widget.isExporting
                  ? null
                  : (mode) {
                      setState(() {
                        _exportMode = mode;
                      });
                    },
            ),

            const SizedBox(height: 16),

            // Quality
            QualitySelector(
              selectedQuality: _quality,
              onQualityChanged: widget.isExporting
                  ? null
                  : (quality) {
                      setState(() {
                        _quality = quality;
                      });
                    },
            ),

            const SizedBox(height: 16),

            // Page format
            FormatSelector(
              selectedFormat: _pageFormat,
              onFormatChanged: widget.isExporting
                  ? null
                  : (format) {
                      setState(() {
                        _pageFormat = format;
                      });
                    },
            ),

            const SizedBox(height: 16),

            // Include background
            SwitchListTile(
              title: const Text('Include backgrounds'),
              value: _includeBackground,
              onChanged: widget.isExporting
                  ? null
                  : (value) {
                      setState(() {
                        _includeBackground = value;
                      });
                    },
            ),

            const Spacer(),

            // Progress indicator
            if (widget.isExporting) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
              if (widget.progressMessage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    widget.progressMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.isExporting ? null : _handleCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: widget.isExporting ? null : _handleExport,
                  child: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for selecting export mode.
class ExportModeSelector extends StatelessWidget {
  final PDFExportMode selectedMode;
  final ValueChanged<PDFExportMode>? onModeChanged;

  const ExportModeSelector({
    super.key,
    required this.selectedMode,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Mode',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        RadioListTile<PDFExportMode>(
          title: const Text('Vector'),
          subtitle: const Text('Best quality, smaller file size'),
          value: PDFExportMode.vector,
          groupValue: selectedMode,
          onChanged: (mode) => mode != null ? onModeChanged(mode) : null,
        ),
        RadioListTile<PDFExportMode>(
          title: const Text('Raster'),
          subtitle: const Text('Image-based, handles complex content'),
          value: PDFExportMode.raster,
          groupValue: selectedMode,
          onChanged: (mode) => mode != null ? onModeChanged(mode) : null,
        ),
        RadioListTile<PDFExportMode>(
          title: const Text('Hybrid'),
          subtitle: const Text('Balanced approach, automatic fallback'),
          value: PDFExportMode.hybrid,
          groupValue: selectedMode,
          onChanged: (mode) => mode != null ? onModeChanged(mode) : null,
        ),
      ],
    );
  }
}

/// Widget for selecting export quality.
class QualitySelector extends StatelessWidget {
  final PDFExportQuality selectedQuality;
  final ValueChanged<PDFExportQuality>? onQualityChanged;

  const QualitySelector({
    super.key,
    required this.selectedQuality,
    this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<PDFExportQuality>(
          segments: const [
            ButtonSegment(
              value: PDFExportQuality.low,
              label: Text('Low'),
              tooltip: '72 DPI',
            ),
            ButtonSegment(
              value: PDFExportQuality.medium,
              label: Text('Medium'),
              tooltip: '150 DPI',
            ),
            ButtonSegment(
              value: PDFExportQuality.high,
              label: Text('High'),
              tooltip: '300 DPI',
            ),
            ButtonSegment(
              value: PDFExportQuality.print,
              label: Text('Print'),
              tooltip: '600 DPI',
            ),
          ],
          selected: {selectedQuality},
          onSelectionChanged: onQualityChanged == null
              ? null
              : (Set<PDFExportQuality> selection) {
                  onQualityChanged!(selection.first);
                },
        ),
      ],
    );
  }
}

/// Widget for selecting page format.
class FormatSelector extends StatelessWidget {
  final PDFPageFormat selectedFormat;
  final ValueChanged<PDFPageFormat>? onFormatChanged;

  const FormatSelector({
    super.key,
    required this.selectedFormat,
    this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Page Format',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PDFPageFormat>(
          value: selectedFormat,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            DropdownMenuItem(
              value: PDFPageFormat.a4,
              child: Text('A4 (${PDFPageFormat.a4.width.toInt()} × ${PDFPageFormat.a4.height.toInt()})'),
            ),
            DropdownMenuItem(
              value: PDFPageFormat.a5,
              child: Text('A5 (${PDFPageFormat.a5.width.toInt()} × ${PDFPageFormat.a5.height.toInt()})'),
            ),
            DropdownMenuItem(
              value: PDFPageFormat.letter,
              child: Text('Letter (${PDFPageFormat.letter.width.toInt()} × ${PDFPageFormat.letter.height.toInt()})'),
            ),
            DropdownMenuItem(
              value: PDFPageFormat.legal,
              child: Text('Legal (${PDFPageFormat.legal.width.toInt()} × ${PDFPageFormat.legal.height.toInt()})'),
            ),
          ],
          onChanged: (format) => format != null && onFormatChanged != null ? onFormatChanged!(format) : null,
        ),
      ],
    );
  }
}
