import 'dart:convert';

import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart';

/// 1x1 transparent PNG: a cached thumbnail that paints nothing, so the
/// sidebar shows blank paper instead of a loading spinner.
final _blankPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// [count] portrait pages with stable ids and dates; [bookmarked] holds the
/// indexes of bookmarked pages.
List<core.Page> sidebarPages(int count, {Set<int> bookmarked = const {}}) {
  final date = DateTime(2026, 1, 1);
  return [
    for (var i = 0; i < count; i++)
      core.Page(
        id: 'page_$i',
        index: i,
        size: core.PageSize.a4Portrait,
        createdAt: date,
        updatedAt: date,
        isBookmarked: bookmarked.contains(i),
      ),
  ];
}

/// A [ThumbnailCache] that already holds a blank thumbnail for every page.
ThumbnailCache sidebarCache(List<core.Page> pages) {
  final cache = ThumbnailCache();
  for (final page in pages) {
    cache.put(ThumbnailGenerator.getCacheKey(page), _blankPng);
  }
  return cache;
}
