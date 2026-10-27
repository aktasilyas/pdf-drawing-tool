import 'package:drawing_core/drawing_core.dart' show PageBackground;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart'
    show renderThumbnail, pdfThumbnailCacheProvider;
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Low-res thumbnail of a PDF page background, rendered through
/// [renderThumbnail] and cached in [pdfThumbnailCacheProvider].
class PdfPageThumbnail extends ConsumerWidget {
  const PdfPageThumbnail({super.key, required this.background});

  /// A PDF background with `pdfFilePath` and `pdfPageIndex` set.
  final PageBackground background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheKey = '${background.pdfFilePath}|${background.pdfPageIndex}';

    // 1. Thumbnail cache first.
    final thumbCache = ref.watch(pdfThumbnailCacheProvider);
    if (thumbCache.containsKey(cacheKey)) {
      return Image.memory(
        thumbCache[cacheKey]!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }

    // 2. Do not start loading while scrolling fast.
    final shouldDefer = Scrollable.recommendDeferredLoadingForContext(context);
    if (!shouldDefer) {
      // Use the ProviderContainer (dispose-safe).
      final container = ProviderScope.containerOf(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        renderThumbnail(container, cacheKey);
      });
    }

    // 3. Simple placeholder.
    final cs = Theme.of(context).colorScheme;
    return Container(
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
