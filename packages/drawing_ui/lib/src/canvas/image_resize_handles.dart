import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_handles_geometry.dart';
import 'package:drawing_ui/src/canvas/image_handles_painter.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/image_provider.dart';
import 'package:drawing_ui/src/providers/infinite_canvas_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';

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
  ConsumerState<ImageResizeHandles> createState() => _ImageResizeHandlesState();
}

class _ImageResizeHandlesState extends ConsumerState<ImageResizeHandles> {
  _DragMode? _dragMode;
  ImageCorner? _activeCorner;
  ImageElement? _originalImage;
  Offset? _lastDragPos;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Report the touch-down point so handle hit tests are not offset by
      // the pan slop.
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: _onTapUp,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: ImageHandlesPainter(
          image: widget.image,
          selectionColor: Theme.of(context).colorScheme.primary,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  ImagePlacementNotifier get _placement =>
      ref.read(imagePlacementProvider.notifier);

  void _onTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    final img = widget.image;

    // Tap on rotation handle or corner → ignore (intended drag)
    if (ImageHandlesGeometry.hitRotationHandle(pos, img)) return;
    if (ImageHandlesGeometry.hitCorner(pos, img) != null) return;

    final local = ImageHandlesGeometry.toLocal(pos, img);
    if (ImageHandlesGeometry.isInsideLocal(local, img)) {
      _placement.selectImage(img);
    } else {
      _placement.deselectImage();
    }
  }

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    final img = widget.image;

    if (ImageHandlesGeometry.hitRotationHandle(pos, img)) {
      _begin(_DragMode.rotate, img, pos);
      return;
    }
    final corner = ImageHandlesGeometry.hitCorner(pos, img);
    if (corner != null) {
      _activeCorner = corner;
      _begin(_DragMode.resize, img, pos);
      return;
    }
    final local = ImageHandlesGeometry.toLocal(pos, img);
    if (ImageHandlesGeometry.isInsideLocal(local, img)) {
      _begin(_DragMode.move, img, pos);
      return;
    }
    _placement.deselectImage();
  }

  void _begin(_DragMode mode, ImageElement img, Offset pos) {
    _dragMode = mode;
    _originalImage = img;
    _lastDragPos = pos;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final orig = _originalImage;
    if (_dragMode == null || orig == null) return;
    final pos = details.localPosition;

    switch (_dragMode!) {
      case _DragMode.resize:
        final corner = _activeCorner;
        if (corner == null) return;
        final local = ImageHandlesGeometry.toLocal(pos, orig);
        _placement.updateSelectedImage(
            ImageHandlesGeometry.resize(corner, orig, local));
        break;

      case _DragMode.move:
        final delta = pos - _lastDragPos!;
        _lastDragPos = pos;
        final cur = ref.read(imagePlacementProvider).selectedImage ?? orig;
        final moved = cur.copyWith(x: cur.x + delta.dx, y: cur.y + delta.dy);
        _placement.updateSelectedImage(ref.read(isInfiniteCanvasProvider)
            ? moved
            : ImageHandlesGeometry.clampToPage(
                moved,
                ref.read(currentPageProvider).size.width,
                ref.read(currentPageProvider).size.height));
        break;

      case _DragMode.rotate:
        _placement.updateSelectedImage(orig.copyWith(
            rotation: ImageHandlesGeometry.rotationFor(pos, orig)));
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final orig = _originalImage;
    final current = ref.read(imagePlacementProvider).selectedImage;
    if (_dragMode != null &&
        orig != null &&
        current != null &&
        current.id == orig.id &&
        ImageHandlesGeometry.changed(orig, current)) {
      ref.read(historyManagerProvider.notifier).execute(UpdateImageCommand(
            layerIndex: ref.read(documentProvider).activeLayerIndex,
            newImage: current,
          ));
    }
    _reset();
  }

  void _reset() {
    _dragMode = null;
    _activeCorner = null;
    _originalImage = null;
    _lastDragPos = null;
  }
}
