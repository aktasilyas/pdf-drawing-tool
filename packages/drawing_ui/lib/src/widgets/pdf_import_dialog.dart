import 'package:flutter/material.dart';

/// Mode for PDF import.
enum PDFImportMode {
  /// Import all pages from the PDF.
  allPages,

  /// Import a specific page range.
  pageRange,

  /// Import selected pages.
  selectedPages,
}

/// Result of PDF import operation.
class PDFImportResult {
  /// Whether the import was successful.
  final bool isSuccess;

  /// Number of pages imported.
  final int pageCount;

  /// Error message if import failed.
  final String? errorMessage;

  const PDFImportResult({
    required this.isSuccess,
    required this.pageCount,
    this.errorMessage,
  });

  /// Creates a successful import result.
  factory PDFImportResult.success({required int pageCount}) {
    return PDFImportResult(
      isSuccess: true,
      pageCount: pageCount,
    );
  }

  /// Creates an error import result.
  factory PDFImportResult.error(String message) {
    return PDFImportResult(
      isSuccess: false,
      pageCount: 0,
      errorMessage: message,
    );
  }

  /// Creates a cancelled import result.
  factory PDFImportResult.cancelled() {
    return PDFImportResult(
      isSuccess: false,
      pageCount: 0,
    );
  }
}

/// Dialog for importing PDF files.
class PDFImportDialog extends StatefulWidget {
  /// Whether the dialog is currently loading.
  final bool isLoading;

  /// Progress message during loading.
  final String? progressMessage;

  /// Error message to display.
  final String? errorMessage;

  /// Callback when import is completed.
  final void Function(PDFImportResult result)? onImportComplete;

  const PDFImportDialog({
    super.key,
    this.isLoading = false,
    this.progressMessage,
    this.errorMessage,
    this.onImportComplete,
  });

  @override
  State<PDFImportDialog> createState() => _PDFImportDialogState();
}

class _PDFImportDialogState extends State<PDFImportDialog> {
  PDFImportMode _importMode = PDFImportMode.allPages;
  String? _selectedFilePath;
  int _totalPages = 0;
  int _startPage = 1;
  int _endPage = 1;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
    _errorMessage = widget.errorMessage;
  }

  @override
  void didUpdateWidget(PDFImportDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      setState(() {
        _isLoading = widget.isLoading;
      });
    }
    if (widget.errorMessage != oldWidget.errorMessage) {
      setState(() {
        _errorMessage = widget.errorMessage;
      });
    }
  }

  bool get _canImport =>
      _selectedFilePath != null && !_isLoading && _errorMessage == null;

  void _handleFileSelect() {
    // File picker implementation would go here
    // For now, this is a placeholder
    setState(() {
      _errorMessage = null;
    });
  }

  void _handleImport() {
    if (!_canImport) return;

    // Import logic would go here
    // For now, return a mock result
    widget.onImportComplete?.call(
      PDFImportResult.success(pageCount: _totalPages),
    );
  }

  void _handleCancel() {
    if (_isLoading) return;

    Navigator.of(context).pop(PDFImportResult.cancelled());
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
              'Import PDF',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
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
                        _errorMessage!,
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

            // File selector
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleFileSelect,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _selectedFilePath == null
                    ? 'Select PDF File'
                    : 'Change PDF File',
              ),
            ),

            if (_selectedFilePath != null) ...[
              const SizedBox(height: 8),
              Text(
                _selectedFilePath!,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 24),

            // Import options
            Text(
              'Import Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            RadioListTile<PDFImportMode>(
              title: const Text('Import all pages'),
              value: PDFImportMode.allPages,
              groupValue: _importMode,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _importMode = value;
                        });
                      }
                    },
            ),

            RadioListTile<PDFImportMode>(
              title: const Text('Select page range'),
              value: PDFImportMode.pageRange,
              groupValue: _importMode,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _importMode = value;
                        });
                      }
                    },
            ),

            if (_importMode == PDFImportMode.pageRange &&
                _totalPages > 0) ...[
              const SizedBox(height: 12),
              PageRangeSelector(
                totalPages: _totalPages,
                startPage: _startPage,
                endPage: _endPage,
                onRangeChanged: _isLoading
                    ? null
                    : (start, end) {
                        setState(() {
                          _startPage = start;
                          _endPage = end;
                        });
                      },
              ),
            ],

            const Spacer(),

            // Progress indicator
            if (_isLoading) ...[
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
                  onPressed: _isLoading ? null : _handleCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _canImport ? _handleImport : null,
                  child: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for selecting a page range.
class PageRangeSelector extends StatelessWidget {
  /// Total number of pages in the PDF.
  final int totalPages;

  /// Starting page number (1-based).
  final int startPage;

  /// Ending page number (1-based).
  final int endPage;

  /// Callback when range changes.
  final void Function(int start, int end)? onRangeChanged;

  const PageRangeSelector({
    super.key,
    required this.totalPages,
    required this.startPage,
    required this.endPage,
    this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startPage.toString(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endPage.toString(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total: ${endPage - startPage + 1} of $totalPages pages',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
