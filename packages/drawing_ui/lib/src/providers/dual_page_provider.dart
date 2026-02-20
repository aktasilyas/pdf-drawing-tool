import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_provider.dart';
import 'page_provider.dart';

/// Whether dual page (side-by-side) mode is active.
final dualPageModeProvider = StateProvider<bool>((ref) => false);

/// The next page to display in the secondary (read-only) pane.
/// Returns null when dual mode is off or the current page is the last one.
///
/// Uses [documentProvider] (not pageManagerProvider) because the document
/// holds the canonical page content — strokes, shapes, texts, etc.
/// The pageManagerProvider pages can become stale after drawing operations.
final secondaryPageProvider = Provider<Page?>((ref) {
  if (!ref.watch(dualPageModeProvider)) return null;
  final doc = ref.watch(documentProvider);
  final currentIdx = ref.watch(currentPageIndexProvider);
  final nextIdx = currentIdx + 1;
  if (nextIdx >= doc.pages.length) return null;
  return doc.pages[nextIdx];
});
