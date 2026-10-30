import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Loading placeholder of a PDF page thumbnail, shown until the page
/// rasterizer has rendered the PDF background with its annotations (#496).
class PdfThumbnailPlaceholder extends StatelessWidget {
  const PdfThumbnailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: PhosphorIcon(
          ElyanotesIcons.pdfFile,
          size: 24,
          color: cs.outlineVariant,
        ),
      ),
    );
  }
}
