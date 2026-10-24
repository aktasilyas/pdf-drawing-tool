import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/rendering/element_scene_renderer.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'package:drawing_ui/src/rendering/tiles/element_scene.dart';

/// Builds the vector renderer that paints [scene] (used to fill tiles and as
/// the fallback for tiles that are not rasterized yet).
ElementSceneRenderer buildSceneRenderer(
  ElementScene s,
  FlutterStrokeRenderer strokeRenderer,
  ImageCacheManager cacheManager,
) =>
    ElementSceneRenderer(
      strokes: s.strokes,
      shapes: s.shapes,
      images: s.images,
      texts: s.texts,
      elementOrder: s.elementOrder,
      renderer: strokeRenderer,
      cacheManager: cacheManager,
      excludedStrokeIds: s.excludedIds,
      excludedShapeIds: s.excludedIds,
      excludedImageIds: s.excludedIds,
      excludedTextIds: s.excludedIds,
      pixelEraserPreview: s.pixelEraserPreview,
      strokeEraserPreview: s.strokeEraserPreview,
    );

/// Scene made of only [entries] (in [order]) that keeps [scene]'s previews.
ElementScene subScene(
  ElementScene scene,
  List<SceneEntry> entries,
  List<String> order,
) =>
    ElementScene(
      strokes: [
        for (final e in entries)
          if (e.element is Stroke) e.element as Stroke,
      ],
      shapes: [
        for (final e in entries)
          if (e.element is Shape) e.element as Shape,
      ],
      images: [
        for (final e in entries)
          if (e.element is ImageElement) e.element as ImageElement,
      ],
      texts: [
        for (final e in entries)
          if (e.element is TextElement) e.element as TextElement,
      ],
      elementOrder: order,
      pixelEraserPreview: scene.pixelEraserPreview,
    );
