import 'package:flutter/material.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/services/pdf_page_range.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Asks which pages of a [pageCount]-page PDF to import, at most [maxPages].
///
/// Returns the chosen range, or null when the user cancels or dismisses.
Future<PdfPageRange?> showPdfPageRangeSheet(
  BuildContext context, {
  required int pageCount,
  required int maxPages,
}) =>
    showModalBottomSheet<PdfPageRange>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          PdfPageRangeSheet(pageCount: pageCount, maxPages: maxPages),
    );

/// Content of the page-range sheet; use [showPdfPageRangeSheet].
class PdfPageRangeSheet extends StatefulWidget {
  const PdfPageRangeSheet({
    super.key,
    required this.pageCount,
    required this.maxPages,
    this.initiallyChoosing = false,
    this.initialStart,
    this.initialEnd,
  });

  final int pageCount;
  final int maxPages;

  /// Opens with the range fields visible (goldens).
  final bool initiallyChoosing;
  final int? initialStart;
  final int? initialEnd;

  @override
  State<PdfPageRangeSheet> createState() => _PdfPageRangeSheetState();
}

class _PdfPageRangeSheetState extends State<PdfPageRangeSheet> {
  late bool _choosing = widget.initiallyChoosing;
  late int _start = widget.initialStart ?? 1;
  late int _end = widget.initialEnd ?? widget.maxPages;

  PdfPageRangeError? get _error => validatePdfPageRange(
        _start,
        _end,
        total: widget.pageCount,
        max: widget.maxPages,
      );

  void _pop([PdfPageRange? range]) => Navigator.of(context).pop(range);

  @override
  Widget build(BuildContext context) {
    final s = context.drawingStrings.pages;
    final theme = Theme.of(context);
    final error = _error;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        ChromeSpacing.lg,
        0,
        ChromeSpacing.lg,
        ChromeSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.pdfRangeTitle(widget.pageCount),
              style: theme.textTheme.titleLarge),
          const SizedBox(height: ChromeSpacing.xs),
          Text(
            s.pdfRangeLimitHint(widget.maxPages),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: ChromeSpacing.lg),
          _action(
            FilledButton(
              key: const ValueKey('pdf-range-first'),
              onPressed: () => _pop(PdfPageRange(1, widget.maxPages)),
              child: Text(s.pdfRangeImportFirst(widget.maxPages)),
            ),
          ),
          const SizedBox(height: ChromeSpacing.sm),
          if (!_choosing)
            _action(
              OutlinedButton(
                key: const ValueKey('pdf-range-choose'),
                onPressed: () => setState(() => _choosing = true),
                child: Text(s.pdfRangeChoose),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    const ValueKey('pdf-range-start'),
                    s.pdfRangeStart,
                    _start,
                    (v) => setState(() => _start = v),
                  ),
                ),
                const SizedBox(width: ChromeSpacing.sm),
                Expanded(
                  child: _field(
                    const ValueKey('pdf-range-end'),
                    s.pdfRangeEnd,
                    _end,
                    (v) => setState(() => _end = v),
                  ),
                ),
              ],
            ),
            if (error != null)
              Padding(
                key: const ValueKey('pdf-range-error'),
                padding: const EdgeInsets.only(top: ChromeSpacing.xs),
                child: Text(
                  s.pdfRangeError(error, widget.pageCount, widget.maxPages),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: ChromeSpacing.sm),
            _action(
              FilledButton.tonal(
                key: const ValueKey('pdf-range-import'),
                onPressed: error == null
                    ? () => _pop(PdfPageRange(_start, _end))
                    : null,
                child: Text(s.pdfRangeImport),
              ),
            ),
          ],
          const SizedBox(height: ChromeSpacing.xs),
          _action(
            TextButton(
              key: const ValueKey('pdf-range-cancel'),
              onPressed: _pop,
              child: Text(s.pdfRangeCancel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(Widget button) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: button,
      );

  Widget _field(
    Key key,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) =>
      TextFormField(
        key: key,
        initialValue: '$value',
        keyboardType: TextInputType.number,
        // Not dense: the field stays a >= 48dp touch target.
        decoration: InputDecoration(labelText: label),
        // Unparseable input becomes 0, which validation rejects.
        onChanged: (t) => onChanged(int.tryParse(t) ?? 0),
      );
}
