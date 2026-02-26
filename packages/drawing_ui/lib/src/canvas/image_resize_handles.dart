import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/image_provider.dart';
import 'package:drawing_ui/src/providers/infinite_canvas_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

enum _DragMode { resize, move, rotate }

/// Handles for resizing, moving, and rotating a selected image.
///
/// Placed inside the Transform stack (canvas coordinates).
/// - Drag a corner → resize.
/// - Drag the body → live move (clamped to page bounds).
/// - Drag the rotation handle (above top-center) → rotate.
/// - Tap the body → show context menu.
/// - Tap outside → deselect.
class ImageResizeHandles extends ConsumerStatefulWidget {
  final ImageElement image;

  const ImageResizeHandles({super.key, required this.image});

  @override
  ConsumerState<ImageResizeHandles> createState() =>
      _ImageResizeHandlesState();
}

class _ImageResizeHandlesState extends ConsumerState<ImageResizeHandles> {
  _DragMode? _dragMode;
  _Corner? _activeCorner;
  ImageElement? _originalImage;
  Offset? _lastDragPos;

  static const double _hitRadius = 20.0;
  static const double _minSize = 50.0;
  static const double _rotHandleDist = 30.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _ImageHandlesPainter(image: widget.image),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Coordinate helpers (for rotated images) ──

  Offset _toLocal(Offset point, ImageElement img) {
    if (img.rotation == 0) return point;
    final cx = img.x + img.width / 2;
    final cy = img.y + img.height / 2;
    final c = math.cos(-img.rotation);
    final s = math.sin(-img.rotation);
    final dx = point.dx - cx, dy = point.dy - cy;
    return Offset(cx + dx * c - dy * s, cy + dx * s + dy * c);
  }

  Offset _toCanvas(Offset local, ImageElement img) {
    if (img.rotation == 0) return local;
    final cx = img.x + img.width / 2;
    final cy = img.y + img.height / 2;
    final c = math.cos(img.rotation);
    final s = math.sin(img.rotation);
    final dx = local.dx - cx, dy = local.dy - cy;
    return Offset(cx + dx * c - dy * s, cy + dx * s + dy * c);
  }

  bool _isInsideLocal(Offset local, ImageElement img) {
    return local.dx >= img.x &&
        local.dx <= img.x + img.width &&
        local.dy >= img.y &&
        local.dy <= img.y + img.height;
  }

  Offset _rotHandleLocal(ImageElement img) =>
      Offset(img.x + img.width / 2, img.y - _rotHandleDist);

  Map<_Corner, Offset> _localCorners(ImageElement img) => {
        _Corner.topLeft: Offset(img.x, img.y),
        _Corner.topRight: Offset(img.x + img.width, img.y),
        _Corner.bottomLeft: Offset(img.x, img.y + img.height),
        _Corner.bottomRight: Offset(img.x + img.width, img.y + img.height),
      };

  _Corner? _hitCorner(Offset canvasPos, ImageElement img) {
    for (final e in _localCorners(img).entries) {
      if ((canvasPos - _toCanvas(e.value, img)).distance <= _hitRadius) {
        return e.key;
      }
    }
    return null;
  }

  /// Clamp image position so it stays within the page bounds.
  ImageElement _clampToPage(ImageElement img) {
    final page = ref.read(currentPageProvider);
    final pw = page.size.width;
    final ph = page.size.height;
    final clampedX = img.x.clamp(0.0, (pw - img.width).clamp(0.0, pw));
    final clampedY = img.y.clamp(0.0, (ph - img.height).clamp(0.0, ph));
    return img.copyWith(x: clampedX, y: clampedY);
  }

  // ── Tap handler (short tap — no drag) ──

  void _onTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    final img = widget.image;

    // Tap on rotation handle or corner → ignore (intended drag)
    if ((pos - _toCanvas(_rotHandleLocal(img), img)).distance <= _hitRadius) {
      return;
    }
    if (_hitCorner(pos, img) != null) return;

    // Tap inside body → show context menu
    if (_isInsideLocal(_toLocal(pos, img), img)) {
      ref.read(imagePlacementProvider.notifier).selectImage(img);
      return;
    }

    // Outside → deselect
    ref.read(imagePlacementProvider.notifier).deselectImage();
  }

  // ── Pan handlers (drag) ──

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    final img = widget.image;

    // Rotation handle
    if ((pos - _toCanvas(_rotHandleLocal(img), img)).distance <= _hitRadius) {
      _dragMode = _DragMode.rotate;
      _originalImage = img;
      _lastDragPos = pos;
      return;
    }

    // Corners
    final corner = _hitCorner(pos, img);
    if (corner != null) {
      _dragMode = _DragMode.resize;
      _activeCorner = corner;
      _originalImage = img;
      _lastDragPos = pos;
      return;
    }

    // Body
    if (_isInsideLocal(_toLocal(pos, img), img)) {
      _dragMode = _DragMode.move;
      _originalImage = img;
      _lastDragPos = pos;
      return;
    }

    // Outside
    ref.read(imagePlacementProvider.notifier).deselectImage();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragMode == null || _originalImage == null) return;
    final pos = details.localPosition;

    switch (_dragMode!) {
      case _DragMode.resize:
        if (_activeCorner == null) return;
        final local = _toLocal(pos, _originalImage!);
        final resized = _calcResize(_activeCorner!, _originalImage!, local);
        ref.read(imagePlacementProvider.notifier).updateSelectedImage(resized);
        break;

      case _DragMode.move:
        final delta = pos - _lastDragPos!;
        _lastDragPos = pos;
        final cur =
            ref.read(imagePlacementProvider).selectedImage ?? _originalImage!;
        final moved = cur.copyWith(x: cur.x + delta.dx, y: cur.y + delta.dy);
        ref.read(imagePlacementProvider.notifier).updateSelectedImage(
            ref.read(isInfiniteCanvasProvider) ? moved : _clampToPage(moved));
        break;

      case _DragMode.rotate:
        final img = _originalImage!;
        final cx = img.x + img.width / 2;
        final cy = img.y + img.height / 2;
        final angle = math.atan2(pos.dy - cy, pos.dx - cx) + math.pi / 2;
        final rotated = img.copyWith(rotation: angle);
        ref.read(imagePlacementProvider.notifier).updateSelectedImage(rotated);
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragMode == null || _originalImage == null) {
      _reset();
      return;
    }

    final current = ref.read(imagePlacementProvider).selectedImage;
    if (current != null && current.id == _originalImage!.id) {
      final o = _originalImage!;
      final changed = current.x != o.x ||
          current.y != o.y ||
          current.width != o.width ||
          current.height != o.height ||
          current.rotation != o.rotation;

      if (changed) {
        final document = ref.read(documentProvider);
        final command = UpdateImageCommand(
          layerIndex: document.activeLayerIndex,
          newImage: current,
        );
        ref.read(historyManagerProvider.notifier).execute(command);
      }
    }
    _reset();
  }

  void _reset() {
    _dragMode = null;
    _activeCorner = null;
    _originalImage = null;
    _lastDragPos = null;
  }

  ImageElement _calcResize(
      _Corner corner, ImageElement orig, Offset local) {
    double newX = orig.x, newY = orig.y;
    double newW = orig.width, newH = orig.height;

    switch (corner) {
      case _Corner.bottomRight:
        newW = math.max(_minSize, local.dx - orig.x);
        newH = math.max(_minSize, local.dy - orig.y);
        break;
      case _Corner.bottomLeft:
        final right = orig.x + orig.width;
        newW = math.max(_minSize, right - local.dx);
        newX = right - newW;
        newH = math.max(_minSize, local.dy - orig.y);
        break;
      case _Corner.topRight:
        final bottom = orig.y + orig.height;
        newW = math.max(_minSize, local.dx - orig.x);
        newH = math.max(_minSize, bottom - local.dy);
        newY = bottom - newH;
        break;
      case _Corner.topLeft:
        final right = orig.x + orig.width;
        final bottom = orig.y + orig.height;
        newW = math.max(_minSize, right - local.dx);
        newH = math.max(_minSize, bottom - local.dy);
        newX = right - newW;
        newY = bottom - newH;
        break;
    }
    return orig.copyWith(x: newX, y: newY, width: newW, height: newH);
  }
}

/// Paints blue border, 4 corner handles, and rotation handle with arrow icon.
class _ImageHandlesPainter extends CustomPainter {
  final ImageElement image;
  static const double _r = 8.0;
  static const double _rotDist = 30.0;

  _ImageHandlesPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(image.x, image.y, image.width, image.height);
    final cx = image.x + image.width / 2;
    final cy = image.y + image.height / 2;

    canvas.save();
    if (image.rotation != 0) {
      canvas.translate(cx, cy);
      canvas.rotate(image.rotation);
      canvas.translate(-cx, -cy);
    }

    // Border
    final border = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, border);

    // Corner handles
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleStroke = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final c in [
      rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight,
    ]) {
      canvas.drawCircle(c, _r, fill);
      canvas.drawCircle(c, _r, handleStroke);
    }

    // Rotation handle: line + circle above top-center
    final topCenter = Offset(cx, image.y);
    final rotHandle = Offset(cx, image.y - _rotDist);
    canvas.drawLine(topCenter, rotHandle, border);
    canvas.drawCircle(rotHandle, _r, fill);
    canvas.drawCircle(rotHandle, _r, handleStroke);

    // Circular arrow icon inside rotation handle
    _drawRotationArrow(canvas, rotHandle);

    canvas.restore();
  }

  /// Draws a small circular arrow (↻) inside the rotation handle circle.
  void _drawRotationArrow(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Arc: ~270° sweep starting from top
    const arcRadius = 4.0;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    canvas.drawArc(arcRect, -math.pi * 0.75, math.pi * 1.5, false, paint);

    // Arrowhead at the end of the arc
    final arrowTip = Offset(
      center.dx + arcRadius * math.cos(math.pi * 0.75),
      center.dy + arcRadius * math.sin(math.pi * 0.75),
    );
    final arrowPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    final path = Path();
    // Small triangle pointing in the arc's tangent direction
    path.moveTo(arrowTip.dx - 3, arrowTip.dy - 1);
    path.lineTo(arrowTip.dx + 1, arrowTip.dy - 3);
    path.lineTo(arrowTip.dx + 1, arrowTip.dy + 2);
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(_ImageHandlesPainter oldDelegate) {
    return oldDelegate.image.x != image.x ||
        oldDelegate.image.y != image.y ||
        oldDelegate.image.width != image.width ||
        oldDelegate.image.height != image.height ||
        oldDelegate.image.rotation != image.rotation;
  }
}
