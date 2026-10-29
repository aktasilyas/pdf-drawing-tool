import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/pdf_page_cache.dart';
import 'package:drawing_ui/src/providers/pdf_path_provider.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';

/// Lets the user pick the source PDF again. Returns true once the file is
/// back at [storedPath]; the host does the picking and shows its own feedback.
typedef PdfSourceRelinkHandler = Future<bool> Function(String storedPath);

/// Set by the host to enable the "Locate PDF" action on the missing-source
/// placeholder. `null` (the default) hides the action.
final pdfSourceRelinkProvider =
    StateProvider<PdfSourceRelinkHandler?>((_) => null);

/// Drops every cached render of [stored] so its pages render again.
///
/// Removes the `'<stored>|...'` entries (including HQ `@<q>x` variants) from
/// the page and thumbnail caches, then invalidates the missing-file check and
/// the render provider of each document page that uses [stored].
void evictPdfSource(ProviderContainer container, String stored) {
  final prefix = '$stored|';
  for (final cache in [pdfPageCacheProvider, pdfThumbnailCacheProvider]) {
    final current = container.read(cache);
    if (!current.keys.any((k) => k.startsWith(prefix))) continue;
    container.read(cache.notifier).state = {
      for (final e in current.entries)
        if (!e.key.startsWith(prefix)) e.key: e.value,
    };
  }

  container.invalidate(pdfSourceMissingProvider(stored));
  for (final page in container.read(documentProvider).pages) {
    final bg = page.background;
    if (bg.pdfFilePath == stored && bg.pdfPageIndex != null) {
      container.invalidate(pdfPageRenderProvider('$stored|${bg.pdfPageIndex}'));
    }
  }
}
