import 'dart:ui' as ui;

/// Layout of the notebook object inside a cover render of a given size.
///
/// All measures scale with the render width so the object looks the same at
/// 120 dp and 480 dp. The cover board leaves room on the right/bottom for the
/// page block and the drop shadow.
class CoverGeometry {
  CoverGeometry._(this.size)
      : unit = size.width,
        cover = ui.Rect.fromLTRB(
          size.width * 0.012,
          size.width * 0.012,
          size.width * (1 - 0.06),
          size.height - size.width * 0.06,
        );

  /// Geometry for a render of [size].
  factory CoverGeometry.of(ui.Size size) => CoverGeometry._(size);

  final ui.Size size;

  /// Render width, the base unit for every proportional measure.
  final double unit;

  /// The cover board (without page block and shadow).
  final ui.Rect cover;

  /// Fore-edge corner radius (~6 dp at 240 dp).
  double get radius => unit * 0.025;

  /// Width of the spine/binding band.
  double get spineWidth => unit * 0.08;

  /// Thickness of one visible page-edge layer.
  double get pageEdge => unit * 0.007;

  /// Rounded on the fore-edge side only; square at the spine.
  ui.RRect get coverRRect => ui.RRect.fromRectAndCorners(
        cover,
        topRight: ui.Radius.circular(radius),
        bottomRight: ui.Radius.circular(radius),
      );

  /// The visible face of the cover, right of the hinge crease.
  ui.Rect get face => ui.Rect.fromLTRB(
      cover.left + spineWidth, cover.top, cover.right, cover.bottom);

  /// Title zone: centred on the face, in the upper third.
  ui.Rect get titleRect {
    final w = face.width * 0.74;
    final h = w / 3;
    return ui.Rect.fromLTWH(
        face.center.dx - w / 2, cover.top + cover.height * 0.16, w, h);
  }

  /// Rect of page-block layer [k] (1 = innermost), peeking out right/bottom.
  ui.RRect pageLayer(int k) {
    final e = pageEdge * k;
    return ui.RRect.fromRectAndCorners(
      ui.Rect.fromLTRB(cover.left + spineWidth, cover.top + e, cover.right + e,
          cover.bottom + e),
      topRight: ui.Radius.circular(radius * 0.8),
      bottomRight: ui.Radius.circular(radius * 0.8),
    );
  }
}
