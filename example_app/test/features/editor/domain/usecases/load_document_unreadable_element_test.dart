import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/editor/editor.dart';

import '../../../../helpers/library_fixture.dart';

/// A notebook with one element this app version cannot decode (e.g. a shape
/// type added in a newer version) still opens, and saving keeps the element
/// (#514).
void main() {
  late LibraryFixture fx;
  late String documentId;
  const heart = {'id': 'heart-1', 'type': 'heart', 'petals': 3};

  setUp(() async {
    fx = LibraryFixture();
    documentId =
        (await fx.documents.createDocument(title: 'A', templateId: 'blank'))
            .getOrElse(() => throw StateError('create failed'))
            .id;

    final doc = DrawingDocument.emptyMultiPage('A').copyWith(id: documentId);
    final layer = doc.layers.first.addShape(
      Shape.create(
        type: ShapeType.rectangle,
        startPoint: DrawingPoint(x: 0, y: 0),
        endPoint: DrawingPoint(x: 10, y: 10),
        style: StrokeStyle.pen(),
      ),
    );
    final content = jsonDecode(jsonEncode(doc.updateLayer(0, layer).toJson()))
        as Map<String, dynamic>;
    final layerJson = ((content['pages'] as List).first['layers'] as List).first
        as Map<String, dynamic>;
    (layerJson['shapes'] as List).add(heart);
    (layerJson['elementOrder'] as List).add('heart-1');

    await fx.documents.saveDocumentContent(id: documentId, content: content);
  });

  tearDown(() => fx.close());

  test('LoadDocumentUseCase opens content with one unknown shape', () async {
    final result = await LoadDocumentUseCase(fx.documents)(documentId);

    expect(result.isRight(), isTrue, reason: '$result');
    final layer = result
        .getOrElse(() => throw StateError('load failed'))
        .pages
        .first
        .layers
        .first;
    expect(layer.shapes, hasLength(1));
    expect(layer.unreadableElements.single.raw, heart);
  });

  test('saving the loaded document keeps the unknown shape', () async {
    final loaded = (await LoadDocumentUseCase(fx.documents)(documentId))
        .getOrElse(() => throw StateError('load failed'));

    await fx.documents.saveDocumentContent(
      id: documentId,
      content: loaded.toJson(),
    );
    final stored = (await fx.documents.getDocumentContent(documentId))
        .getOrElse(() => throw StateError('read failed'))!;

    final layerJson = ((stored['pages'] as List).first['layers'] as List).first
        as Map<String, dynamic>;
    expect(layerJson['shapes'], contains(heart));
    expect(layerJson['elementOrder'], contains('heart-1'));
  });
}
