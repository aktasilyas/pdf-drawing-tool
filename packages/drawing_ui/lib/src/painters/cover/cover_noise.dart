import 'dart:math' as math;

/// Deterministic noise helpers for procedural covers.
///
/// Seeds come from a stable FNV-1a hash of the cover id, never from
/// `String.hashCode` or wall-clock time, so goldens stay stable.
class CoverNoise {
  CoverNoise._();

  /// 32-bit FNV-1a hash of the UTF-16 code units of [id].
  static int seedFromId(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash ^= unit & 0xff;
      hash = (hash * 0x01000193) & 0xffffffff;
      hash ^= unit >> 8;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// A seeded random generator for [id] (optionally salted per layer).
  static math.Random randomFor(String id, [int salt = 0]) =>
      math.Random((seedFromId(id) + salt * 0x9e3779b1) & 0x7fffffff);

  /// Uniform double in [min, max).
  static double range(math.Random r, double min, double max) =>
      min + r.nextDouble() * (max - min);
}
