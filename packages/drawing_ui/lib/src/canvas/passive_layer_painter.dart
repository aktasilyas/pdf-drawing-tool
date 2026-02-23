import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' show Layer;
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/unified_element_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_painter.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';

/// Renders a passive (non-active) layer's content.
///
/// All elements are rendered via a single [UnifiedElementPainter] that
/// respects [Layer.elementOrder] for correct z-ordering,
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
        // Unified element painter: strokes, shapes, images, texts
        if (layer.strokes.isNotEmpty ||
            layer.shapes.isNotEmpty ||
            layer.images.isNotEmpty ||
            layer.texts.isNotEmpty)
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: UnifiedElementPainter(
                strokes: layer.strokes,
                shapes: layer.shapes,
                images: layer.images,
                texts: layer.texts,
                elementOrder: layer.elementOrder,
                renderer: renderer,
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
