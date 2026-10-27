import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_core/drawing_core.dart';

/// Corners of an image's bounding box.
enum ImageCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Pure geometry for the image move/resize/rotate handles.
///
/// All methods work in canvas coordinates; rotated images are handled by
/// mapping points into the image's unrotated local frame and back.
abstract final class ImageHandlesGeometry {
  /// Hit radius of a handle in canvas units (48dp touch target).
  static const double hitRadius = 24.0;

  /// Minimum width/height a resize may produce.
  static const double minSize = 50.0;

  /// Distance of the rotation handle above the top edge.
  static const double rotHandleDist = 30.0;

  static Offset center(ImageElement img) =>
      Offset(img.x + img.width / 2, img.y + img.height / 2);

  static Offset _rotate(Offset point, ImageElement img, double angle) {
    if (img.rotation == 0) return point;
    final c = center(img);
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    final dx = point.dx - c.dx, dy = point.dy - c.dy;
    return Offset(c.dx + dx * cos - dy * sin, c.dy + dx * sin + dy * cos);
  }

  /// Canvas point -> image-local (unrotated) frame.
  static Offset toLocal(Offset point, ImageElement img) =>
      _rotate(point, img, -img.rotation);

  /// Image-local (unrotated) point -> canvas.
  static Offset toCanvas(Offset local, ImageElement img) =>
      _rotate(local, img, img.rotation);

  static bool isInsideLocal(Offset local, ImageElement img) =>
      local.dx >= img.x &&
      local.dx <= img.x + img.width &&
      local.dy >= img.y &&
      local.dy <= img.y + img.height;

  static Offset rotHandleLocal(ImageElement img) =>
      Offset(img.x + img.width / 2, img.y - rotHandleDist);

  static Offset cornerLocal(ImageCorner corner, ImageElement img) {
    switch (corner) {
      case ImageCorner.topLeft:
        return Offset(img.x, img.y);
      case ImageCorner.topRight:
        return Offset(img.x + img.width, img.y);
      case ImageCorner.bottomLeft:
        return Offset(img.x, img.y + img.height);
      case ImageCorner.bottomRight:
        return Offset(img.x + img.width, img.y + img.height);
    }
  }

  static bool hitRotationHandle(Offset canvasPos, ImageElement img) =>
      (canvasPos - toCanvas(rotHandleLocal(img), img)).distance <= hitRadius;

  static ImageCorner? hitCorner(Offset canvasPos, ImageElement img) {
    for (final corner in ImageCorner.values) {
      if ((canvasPos - toCanvas(cornerLocal(corner, img), img)).distance <=
          hitRadius) {
        return corner;
      }
    }
    return null;
  }

  /// Resizes [orig] by dragging [corner] to [local] (image-local frame).
  static ImageElement resize(
      ImageCorner corner, ImageElement orig, Offset local) {
    double newX = orig.x, newY = orig.y;
    double newW = orig.width, newH = orig.height;
    final right = orig.x + orig.width;
    final bottom = orig.y + orig.height;

    switch (corner) {
      case ImageCorner.bottomRight:
        newW = math.max(minSize, local.dx - orig.x);
        newH = math.max(minSize, local.dy - orig.y);
        break;
      case ImageCorner.bottomLeft:
        newW = math.max(minSize, right - local.dx);
        newX = right - newW;
        newH = math.max(minSize, local.dy - orig.y);
        break;
      case ImageCorner.topRight:
        newW = math.max(minSize, local.dx - orig.x);
        newH = math.max(minSize, bottom - local.dy);
        newY = bottom - newH;
        break;
      case ImageCorner.topLeft:
        newW = math.max(minSize, right - local.dx);
        newH = math.max(minSize, bottom - local.dy);
        newX = right - newW;
        newY = bottom - newH;
        break;
    }
    return orig.copyWith(x: newX, y: newY, width: newW, height: newH);
  }

  /// Rotation (radians) that points the top handle at [pos].
  static double rotationFor(Offset pos, ImageElement img) {
    final c = center(img);
    return math.atan2(pos.dy - c.dy, pos.dx - c.dx) + math.pi / 2;
  }

  /// Clamps the image position so it stays within the page.
  static ImageElement clampToPage(
      ImageElement img, double pageWidth, double pageHeight) {
    final x = img.x.clamp(0.0, (pageWidth - img.width).clamp(0.0, pageWidth));
    final y =
        img.y.clamp(0.0, (pageHeight - img.height).clamp(0.0, pageHeight));
    return img.copyWith(x: x, y: y);
  }

  /// Whether a drag changed the image geometry.
  static bool changed(ImageElement a, ImageElement b) =>
      a.x != b.x ||
      a.y != b.y ||
      a.width != b.width ||
      a.height != b.height ||
      a.rotation != b.rotation;
}
