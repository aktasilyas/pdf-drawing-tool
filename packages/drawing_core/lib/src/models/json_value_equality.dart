/// Deep equality for JSON-like values (maps, lists, scalars).
///
/// Internal helper; not exported from the package barrel.
bool jsonDeepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !jsonDeepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonDeepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Hash code consistent with [jsonDeepEquals]. Map hashing is order independent.
int jsonDeepHash(Object? value) {
  if (value is Map) {
    var hash = 0;
    for (final e in value.entries) {
      hash += Object.hash(jsonDeepHash(e.key), jsonDeepHash(e.value));
    }
    return hash;
  }
  if (value is List) return Object.hashAll(value.map(jsonDeepHash));
  return value.hashCode;
}
