import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/providers/pdf_source_relink_provider.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Page-sized stand-in shown when a PDF page rendered nothing.
///
/// Distinguishes a missing source file (`errors.pdfSourceMissing`)
/// from any other render failure (generic `errors.pdfPagePlaceholder`).
class PdfPagePlaceholder extends ConsumerWidget {
  const PdfPagePlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.pdfFilePath,
  });

  final double width;
  final double height;

  /// Stored path of the source PDF; `null` for pages without one.
  final String? pdfFilePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = pdfFilePath;
    final missing = path != null &&
        (ref.watch(pdfSourceMissingProvider(path)).value ?? false);
    final handler = ref.watch(pdfSourceRelinkProvider);
    final relink = missing ? handler : null;
    final colorScheme = Theme.of(context).colorScheme;
    final errors = context.drawingStrings.errors;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(ChromeSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                missing ? ElyanotesIcons.warningCircle : ElyanotesIcons.pdfFile,
                size: 40,
                color: missing ? colorScheme.error : colorScheme.outlineVariant,
              ),
              const SizedBox(height: ChromeSpacing.sm),
              Text(
                missing ? errors.pdfSourceMissing : errors.pdfPagePlaceholder,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              if (relink != null) ...[
                const SizedBox(height: ChromeSpacing.md),
                FilledButton.tonal(
                  key: const Key('pdfLocateSourceButton'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: colorScheme.onSecondaryContainer,
                    backgroundColor: colorScheme.secondaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ChromeSpacing.lg,
                    ),
                  ),
                  onPressed: () => _relink(context, relink, path!),
                  child: Text(errors.pdfLocateSource),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The widget may unmount while the host picks a file, so the container is
  /// captured before the await.
  Future<void> _relink(
    BuildContext context,
    PdfSourceRelinkHandler handler,
    String stored,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    if (await handler(stored)) evictPdfSource(container, stored);
  }
}
