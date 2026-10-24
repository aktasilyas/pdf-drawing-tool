import 'dart:ui';

/// Edge length of one tile in device pixels.
const int kTilePixels = 512;

/// Column/row of a tile in a [TileGrid].
class TileKey {
  const TileKey(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is TileKey && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => 'TileKey($col, $row)';
}

/// Fixed 512x512 device-pixel tile grid over page space for one [scale]
/// (device pixels per page unit = zoom * devicePixelRatio).
class TileGrid {
  TileGrid({required this.scale, this.tilePixels = kTilePixels})
      : assert(scale > 0),
        tileExtent = tilePixels / scale;

  final double scale;
  final int tilePixels;

  /// Tile edge length in page units.
  final double tileExtent;

  /// Whether [other] equals [scale] within a relative 1e-4 (no exact-double
  /// compare, so float noise from zoom maths does not rebuild the grid).
  bool hasScale(double other) => (scale - other).abs() <= other.abs() * 1e-4;

  /// Page-space rect of [key]. Adjacent tiles share edges exactly.
  Rect rectOf(TileKey key) => Rect.fromLTRB(
        key.col * tileExtent,
        key.row * tileExtent,
        (key.col + 1) * tileExtent,
        (key.row + 1) * tileExtent,
      );

  /// Keys of every tile whose rect overlaps [rect] (touching edges do not
  /// count). When [clip] is given, only tiles overlapping it are returned.
  List<TileKey> keysIn(Rect rect, {Rect? clip}) {
    var r = rect;
    if (clip != null) r = r.intersect(clip);
    if (r.isEmpty || r.left.isNaN || r.top.isNaN) return const [];
    final c0 = (r.left / tileExtent).floor();
    final r0 = (r.top / tileExtent).floor();
    final c1 = _lastIndex(r.right);
    final r1 = _lastIndex(r.bottom);
    return [
      for (var row = r0; row <= r1; row++)
        for (var col = c0; col <= c1; col++) TileKey(col, row),
    ];
  }

  int _lastIndex(double edge) {
    final i = (edge / tileExtent).ceil() - 1;
    return i;
  }
}
