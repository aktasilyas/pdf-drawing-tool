import 'package:drawing_core/drawing_core.dart';

/// Rotation angle for page rotation.
enum RotationAngle {
  /// 90° clockwise.
  cw90,

  /// 90° counter-clockwise.
  ccw90,

  /// 180° (half turn).
  half,
}

/// Rotates a [Page] by the given [RotationAngle].
///
/// Content coordinates are transformed so that elements move to
/// rotated positions, but element orientations are preserved
/// (text stays readable, images keep their original rotation).
abstract final class PageRotationService {
  static Page rotatePage(Page page, RotationAngle angle) {
    final w = page.size.width;
    final h = page.size.height;
    final swapDims = angle != RotationAngle.half;

    final rotatedLayers =
        page.layers.map((l) => _rotateLayer(l, angle, w, h)).toList();

    return Page(
      id: page.id,
      index: page.index,
      size: swapDims
          ? PageSize(width: h, height: w, preset: PagePreset.custom)
          : page.size,
      background: page.background,
      layers: rotatedLayers,
      thumbnail: null,
      createdAt: page.createdAt,
      updatedAt: DateTime.now(),
      isCover: page.isCover,
    );
  }

  // ── Layer ────────────────────────────────────────────────────────

  static Layer _rotateLayer(Layer layer, RotationAngle a, double w, double h) {
    return layer.copyWith(
      strokes: layer.strokes.map((s) => _rotateStroke(s, a, w, h)).toList(),
      shapes: layer.shapes.map((s) => _rotateShape(s, a, w, h)).toList(),
      texts: layer.texts.map((t) => _rotateText(t, a, w, h)).toList(),
      images: layer.images.map((i) => _rotateImage(i, a, w, h)).toList(),
      stickyNotes:
          layer.stickyNotes.map((n) => _rotateStickyNote(n, a, w, h)).toList(),
    );
  }

  // ── Point transform ──────────────────────────────────────────────

  static DrawingPoint _tp(DrawingPoint p, RotationAngle a, double w, double h) {
    return switch (a) {
      RotationAngle.cw90 => p.copyWith(x: h - p.y, y: p.x),
      RotationAngle.ccw90 => p.copyWith(x: p.y, y: w - p.x),
      RotationAngle.half => p.copyWith(x: w - p.x, y: h - p.y),
    };
  }

  // ── Element transforms ───────────────────────────────────────────

  static Stroke _rotateStroke(Stroke s, RotationAngle a, double w, double h) {
    return s.copyWith(
      points: s.points.map((p) => _tp(p, a, w, h)).toList(),
    );
  }

  static Shape _rotateShape(Shape s, RotationAngle a, double w, double h) {
    return s.copyWith(
      startPoint: _tp(s.startPoint, a, w, h),
      endPoint: _tp(s.endPoint, a, w, h),
    );
  }

  static TextElement _rotateText(
      TextElement t, RotationAngle a, double w, double h) {
    final tw = t.width ?? 0;
    final th = t.height ?? 0;
    final cx = t.x + tw / 2;
    final cy = t.y + th / 2;

    final (double ncx, double ncy) = switch (a) {
      RotationAngle.cw90 => (h - cy, cx),
      RotationAngle.ccw90 => (cy, w - cx),
      RotationAngle.half => (w - cx, h - cy),
    };

    // 90° rotations swap the text-box dimensions.
    final swapDims = a != RotationAngle.half;
    final nw = swapDims ? th : tw;
    final nh = swapDims ? tw : th;

    return t.copyWith(
      x: ncx - nw / 2,
      y: ncy - nh / 2,
      width: t.width != null ? nw : null,
      height: t.height != null ? nh : null,
    );
  }

  /// Image center is transformed but the image itself is NOT rotated
  /// (no rotation delta added) so images keep their original orientation.
  static ImageElement _rotateImage(
      ImageElement img, RotationAngle a, double w, double h) {
    final cx = img.x + img.width / 2;
    final cy = img.y + img.height / 2;

    final (double ncx, double ncy) = switch (a) {
      RotationAngle.cw90 => (h - cy, cx),
      RotationAngle.ccw90 => (cy, w - cx),
      RotationAngle.half => (w - cx, h - cy),
    };

    return img.copyWith(
      x: ncx - img.width / 2,
      y: ncy - img.height / 2,
    );
  }

  static StickyNote _rotateStickyNote(
      StickyNote note, RotationAngle a, double w, double h) {
    final cx = note.x + note.width / 2;
    final cy = note.y + note.height / 2;

    final (double ncx, double ncy) = switch (a) {
      RotationAngle.cw90 => (h - cy, cx),
      RotationAngle.ccw90 => (cy, w - cx),
      RotationAngle.half => (w - cx, h - cy),
    };

    final swapDims = a != RotationAngle.half;
    final nw = swapDims ? note.height : note.width;
    final nh = swapDims ? note.width : note.height;

    // Internal strokes/shapes use note-local coordinates.
    final rs = note.strokes
        .map((s) => _rotateStroke(s, a, note.width, note.height))
        .toList();
    final rsh = note.shapes
        .map((s) => _rotateShape(s, a, note.width, note.height))
        .toList();

    return note.copyWith(
      x: ncx - nw / 2,
      y: ncy - nh / 2,
      width: nw,
      height: nh,
      strokes: rs,
      shapes: rsh,
    );
  }
}
