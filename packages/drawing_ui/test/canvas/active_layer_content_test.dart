import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/active_layer_content.dart';
import 'package:drawing_ui/src/canvas/element_preview_painter.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/tiled_element_painter.dart';
import 'package:drawing_ui/src/providers/canvas_transform_provider.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Stroke _stroke(String id, double y) => Stroke(
      id: id,
      points: [
        DrawingPoint(x: 20, y: y),
        DrawingPoint(x: 200, y: y + 20),
      ],
      style: StrokeStyle.pen(thickness: 6),
      createdAt: DateTime(2024),
    );

final Map<int, List<Stroke>> _strokeCache = {};

/// Stable stroke instances: a rebuilt scene must not look like changed ink.
ElementScene _scene(int n) {
  final strokes = [
    for (var i = 0; i < n; i++)
      _strokeCache.putIfAbsent(i, () => [_stroke('s$i', 20.0 + i * 30)]).first,
  ];
  return ElementScene(
    strokes: strokes,
    elementOrder: [for (var i = 0; i < n; i++) 's$i'],
  );
}

final FlutterStrokeRenderer _renderer = FlutterStrokeRenderer();
final ImageCacheManager _manager = ImageCacheManager();

Widget _host({
  required String page,
  required ElementScene scene,
  double zoom = 1,
  bool zooming = false,
  Shape? shape,
  TextElement? text,
}) =>
    MaterialApp(
      home: ActiveLayerContent(
        key: ValueKey(page),
        scene: scene,
        transform: CanvasTransform(zoom: zoom),
        viewportSize: const Size(800, 600),
        isZooming: zooming,
        renderer: _renderer,
        cacheManager: _manager,
        activeShape: shape,
        activeText: text,
      ),
    );

PageTileCache _cache(WidgetTester tester) => tester
    .state<ActiveLayerContentState>(find.byType(ActiveLayerContent))
    .cache;

void main() {
  testWidgets('rasterizes committed content into tiles', (tester) async {
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(2)));
    final cache = _cache(tester);
    expect(cache.debugRasterCount, greaterThan(0));
    expect(cache.visibleTiles, isNotEmpty);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is TiledElementPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('pen-up appends without re-recording the page', (tester) async {
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(20)));
    final cache = _cache(tester);
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(21)));
    expect(cache.debugLastRecordedElements, lessThanOrEqualTo(1));
  });

  testWidgets('zoom only scales cached tiles, re-rasters after ~120 ms', (
    tester,
  ) async {
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(3)));
    final cache = _cache(tester);
    final before = cache.debugRasterCount;

    await tester.pumpWidget(
      _host(page: 'p1', scene: _scene(3), zoom: 2, zooming: true),
    );
    await tester.pumpWidget(
      _host(page: 'p1', scene: _scene(3), zoom: 2.5, zooming: true),
    );
    expect(cache.debugRasterCount, before);

    await tester.pumpWidget(_host(page: 'p1', scene: _scene(3), zoom: 2.5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(cache.debugRasterCount, before, reason: 'still debouncing');

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(cache.debugRasterCount, greaterThan(before));
    expect(cache.hasPending, isFalse);
  });

  testWidgets('a new zoom gesture cancels the pending settle', (tester) async {
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(3)));
    final cache = _cache(tester);
    final before = cache.debugRasterCount;

    await tester.pumpWidget(
      _host(page: 'p1', scene: _scene(3), zoom: 2, zooming: true),
    );
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(3), zoom: 2));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(
      _host(page: 'p1', scene: _scene(3), zoom: 3, zooming: true),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(cache.debugRasterCount, before);
  });

  testWidgets('page change disposes the old cache', (tester) async {
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(2)));
    final old = _cache(tester);
    await tester.pumpWidget(_host(page: 'p2', scene: _scene(1)));
    expect(() => old.addListener(() {}), throwsFlutterError);
    expect(identical(_cache(tester), old), isFalse);
  });

  testWidgets('previews are painted above the tiles, only when present', (
    tester,
  ) async {
    bool hasPreview() => find
        .byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is ElementPreviewPainter,
        )
        .evaluate()
        .isNotEmpty;

    await tester.pumpWidget(_host(page: 'p1', scene: _scene(1)));
    expect(hasPreview(), isFalse);

    final shape = Shape(
      id: 'sh',
      type: ShapeType.rectangle,
      startPoint: DrawingPoint(x: 10, y: 10),
      endPoint: DrawingPoint(x: 60, y: 60),
      style: StrokeStyle.pen(thickness: 2),
    );
    await tester.pumpWidget(_host(page: 'p1', scene: _scene(1), shape: shape));
    expect(hasPreview(), isTrue);
  });
}
