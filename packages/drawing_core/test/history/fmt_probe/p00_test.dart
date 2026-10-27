import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

import '../../helpers/document_helpers.dart';

Layer layer(String id, {List<Stroke> strokes = const []}) {
  return Layer.empty(id).copyWith(id: id, strokes: strokes);
}

Stroke stroke(String id) {
  return Stroke(
    id: id,
    points: [DrawingPoint(x: 0, y: 0), DrawingPoint(x: 10, y: 10)],
    style: StrokeStyle.pen(),
    createdAt: DateTime(2024),
  );
}

DrawingDocument v1(List<Layer> layers, {int active = 0}) {
  return DrawingDocument(
    id: 'd',
    title: 't',
    layers: layers,
    activeLayerIndex: active,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

DrawingDocument v2(List<Layer> layers, {int active = 0}) {
  return multiPageDocWithLayers('t', layers).setActiveLayer(active);
}

List<String> ids(DrawingDocument d) => d.layers.map((l) => l.id).toList();
