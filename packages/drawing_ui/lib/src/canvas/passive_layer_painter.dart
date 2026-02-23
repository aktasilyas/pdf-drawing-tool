import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' show Layer;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/interleaved_object_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

/// Renders a passive (non-active) layer's content.
///
/// All elements are rendered as static CustomPaint layers,
/// wrapped in [Opacity] for the layer's opacity setting,
/// and isolated with [RepaintBoundary] for performance.
class PassiveLayerStack extends StatelessWidget {
  const PassiveLayerStack({
    super.key,
    required this.layer,
    required this.renderer,
    required this.imageCacheManager,
  });

  final Layer layer;
  final FlutterStrokeRenderer renderer;
  final ImageCacheManager imageCacheManager;

  @override
  Widget build(BuildContext context) {
    if (!layer.isVisible) return const SizedBox.shrink();

    Widget content = Stack(
      children: [
        // Strokes
        if (layer.strokes.isNotEmpty)
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: CommittedStrokesPainter(
                strokes: layer.strokes,
                renderer: renderer,
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
        // Shapes
        if (layer.shapes.isNotEmpty)
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: ShapePainter(shapes: layer.shapes),
              isComplex: true,
              willChange: false,
            ),
          ),
        // Images + Texts (interleaved by creation order)
        if (layer.images.isNotEmpty || layer.texts.isNotEmpty)
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: InterleavedObjectPainter(
                images: layer.images,
                texts: layer.texts,
                cacheManager: imageCacheManager,
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
        // Sticky Notes
        if (layer.stickyNotes.isNotEmpty)
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: StickyNotePainter(
                stickyNotes: layer.stickyNotes,
                renderer: renderer,
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
      ],
    );

    // Apply layer opacity
    if (layer.opacity < 1.0) {
      content = Opacity(opacity: layer.opacity, child: content);
    }

    return content;
  }
}
