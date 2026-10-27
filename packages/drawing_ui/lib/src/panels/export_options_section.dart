import 'package:flutter/material.dart';
import 'package:drawing_ui/src/panels/export_options.dart';
import 'package:drawing_ui/src/panels/export_strings.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Page scope, range and template switch shown above the export actions.
class ExportOptionsSection extends StatelessWidget {
  const ExportOptionsSection({
    super.key,
    required this.options,
    required this.pageCount,
    required this.onChanged,
  });

  final ExportOptions options;
  final int pageCount;
  final ValueChanged<ExportOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valid = options.isValid(pageCount);
    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<ExportPageScope>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: ExportPageScope.all,
                  label: Text(ExportStrings.scopeAll)),
              ButtonSegment(
                  value: ExportPageScope.current,
                  label: Text(ExportStrings.scopeCurrent)),
              ButtonSegment(
                  value: ExportPageScope.range,
                  label: Text(ExportStrings.scopeRange)),
            ],
            selected: {options.scope},
            onSelectionChanged: (s) =>
                onChanged(options.copyWith(scope: s.first, to: pageCount)),
          ),
          if (options.scope == ExportPageScope.range) ...[
            const SizedBox(height: ChromeSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    key: const ValueKey('export-range-from'),
                    label: ExportStrings.from,
                    value: options.from,
                    onChanged: (v) => onChanged(options.copyWith(from: v)),
                  ),
                ),
                const SizedBox(width: ChromeSpacing.sm),
                Expanded(
                  child: _NumberField(
                    key: const ValueKey('export-range-to'),
                    label: ExportStrings.to,
                    value: options.to,
                    onChanged: (v) => onChanged(options.copyWith(to: v)),
                  ),
                ),
              ],
            ),
            if (!valid)
              Padding(
                padding: const EdgeInsets.only(top: ChromeSpacing.xs),
                child: Text(ExportStrings.invalidRange(pageCount),
                    style: TextStyle(color: cs.error, fontSize: 12)),
              ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(ExportStrings.includeTemplate),
            value: options.includeTemplate,
            onChanged: (v) => onChanged(options.copyWith(includeTemplate: v)),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
      // Unparseable input becomes 0, which the range validation rejects.
      onChanged: (t) => onChanged(int.tryParse(t) ?? 0),
    );
  }
}
