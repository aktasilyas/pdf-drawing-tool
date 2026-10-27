/// Helpers for commands that remove elements from a layer list and must put
/// them back at their exact original positions on undo.
///
/// Package-internal: not exported from any barrel.
library;

/// An element that was removed from a list, with the index it had there.
class IndexedRemoval<T> {
  /// Position of [element] in the list before anything was removed.
  final int index;

  /// The removed element.
  final T element;

  /// Creates an [IndexedRemoval].
  const IndexedRemoval(this.index, this.element);
}

/// Returns every element of [list] whose id (read with [idOf]) is in [ids],
/// paired with its index, in ascending index order.
List<IndexedRemoval<T>> collectRemovals<T>(
  List<T> list,
  Iterable<String> ids,
  String Function(T element) idOf,
) {
  final wanted = ids.toSet();
  return [
    for (var i = 0; i < list.length; i++)
      if (wanted.contains(idOf(list[i]))) IndexedRemoval(i, list[i]),
  ];
}

/// Returns [current] with each of [removed] re-inserted at its original
/// index.
///
/// [current] must be the list as it was right after the removal (which is
/// what undo sees). Inserting in ascending index order rebuilds the original
/// list exactly, because every element before a given index is already back
/// in place when that index is reached.
List<T> reinsertRemovals<T>(List<T> current, List<IndexedRemoval<T>> removed) {
  if (removed.isEmpty) return current;
  final sorted = [...removed]..sort((a, b) => a.index.compareTo(b.index));
  final result = List<T>.of(current);
  for (final r in sorted) {
    result.insert(r.index.clamp(0, result.length), r.element);
  }
  return result;
}
