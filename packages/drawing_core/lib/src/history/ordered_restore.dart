/// Helpers to put removed elements back at their original list positions.
library;

/// Returns the elements of [list] whose id is in [ids], paired with their
/// index in [list], in list order.
List<MapEntry<int, T>> indexedRemoved<T>(
  List<T> list,
  Iterable<String> ids,
  String Function(T) idOf,
) {
  final wanted = ids.toSet();
  return [
    for (var i = 0; i < list.length; i++)
      if (wanted.contains(idOf(list[i]))) MapEntry(i, list[i]),
  ];
}

/// Re-inserts [removed] (as returned by [indexedRemoved]) into [current] at
/// their original indices.
List<T> reinsertAt<T>(List<T> current, List<MapEntry<int, T>> removed) {
  final result = [...current];
  for (final entry in removed) {
    result.insert(entry.key.clamp(0, result.length), entry.value);
  }
  return result;
}
