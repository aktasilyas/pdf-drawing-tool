import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:drawing_ui/src/rendering/tiles/element_scene.dart';

/// Result of comparing two [ElementScene]s.
class SceneDiff {
  const SceneDiff({
    this.appendedOnTop = const [],
    this.dirty = const [],
    this.full = false,
  });

  /// Everything must be re-rasterized.
  const SceneDiff.full() : this(full: true);

  /// Ids added on top of the z-order with nothing else changed. Tiles can
  /// composite these over their existing image. Mutually exclusive with
  /// [dirty] and [full].
  final List<String> appendedOnTop;

  /// Page-space regions whose pixels changed and need re-recording.
  final List<Rect> dirty;

  /// Survivors changed z-order, or there is no previous scene.
  final bool full;

  bool get isEmpty => !full && appendedOnTop.isEmpty && dirty.isEmpty;
}

/// Compares [prev] to [next] in O(n) by id and object identity.
SceneDiff diffScenes(ElementScene? prev, ElementScene next) {
  if (prev == null) return const SceneDiff.full();
  if (identical(prev, next)) return const SceneDiff();

  final before = prev.entries;
  final after = next.entries;
  final prevById = prev.byId;
  final nextById = next.byId;

  final dirty = <Rect>[];
  var changedExisting = false;

  // Removed and changed elements: old bounds (and new bounds when changed).
  for (final old in before) {
    final cur = nextById[old.id];
    if (cur == null) {
      dirty.add(old.bounds);
      changedExisting = true;
    } else if (_changed(prev, next, old, cur)) {
      dirty.add(old.bounds);
      dirty.add(cur.bounds);
      changedExisting = true;
    }
  }

  // Survivors must keep their relative order, otherwise overlaps change.
  final survivorsBefore = [
    for (final e in before)
      if (nextById.containsKey(e.id)) e.id,
  ];
  final survivorsAfter = [
    for (final e in after)
      if (prevById.containsKey(e.id)) e.id,
  ];
  if (!listEquals(survivorsBefore, survivorsAfter)) {
    return const SceneDiff.full();
  }

  final added = [
    for (final e in after)
      if (!prevById.containsKey(e.id)) e,
  ];

  // Pure append: new ids form the suffix of the new order.
  if (!changedExisting && added.isNotEmpty) {
    final suffixStart = after.length - added.length;
    var isSuffix = true;
    for (var i = 0; i < added.length; i++) {
      if (after[suffixStart + i].id != added[i].id) {
        isSuffix = false;
        break;
      }
    }
    if (isSuffix) {
      return SceneDiff(appendedOnTop: [for (final e in added) e.id]);
    }
  }

  for (final e in added) {
    dirty.add(e.bounds);
  }
  return SceneDiff(dirty: dirty);
}

bool _changed(
  ElementScene prev,
  ElementScene next,
  SceneEntry a,
  SceneEntry b,
) {
  if (!identical(a.element, b.element)) return true;
  return !listEquals(
    prev.pixelEraserPreview[a.id],
    next.pixelEraserPreview[a.id],
  );
}
