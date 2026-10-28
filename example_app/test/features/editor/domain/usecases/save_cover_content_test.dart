import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';
import 'package:drawing_core/drawing_core.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

/// #423: content on the cover page survives a save → load round trip.
void main() {
  late MockDocumentRepository repository;
  Map<String, dynamic>? stored;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    stored = null;
    repository = MockDocumentRepository();
    when(() => repository.saveDocumentContent(
          id: any(named: 'id'),
          content: any(named: 'content'),
          pageCount: any(named: 'pageCount'),
          updatedAt: any(named: 'updatedAt'),
          coverId: any(named: 'coverId'),
          updateCover: any(named: 'updateCover'),
          title: any(named: 'title'),
        )).thenAnswer((inv) async {
      // Same path as the datasource: JSON text on disk.
      stored = jsonDecode(jsonEncode(inv.namedArguments[#content]))
          as Map<String, dynamic>;
      return const Right(null);
    });
    when(() => repository.getDocument('doc')).thenAnswer(
      (_) async => Right(DocumentInfo(
        id: 'doc',
        title: 'Notebook',
        templateId: 'blank',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        pageCount: 2,
        hasCover: true,
        coverId: 'classic_blue',
      )),
    );
    when(() => repository.getDrawingDocument('doc')).thenAnswer(
      (_) async => Right(DrawingDocument.fromJson(stored!)),
    );
  });

  Page coverWithEverything() {
    final style = StrokeStyle.pen(color: 0xFF112233, thickness: 2);
    final stroke = Stroke.create(style: style, points: [
      DrawingPoint(x: 10, y: 10),
      DrawingPoint(x: 40, y: 30),
    ]);
    final shape = Shape.create(
      type: ShapeType.rectangle,
      startPoint: DrawingPoint(x: 50, y: 50),
      endPoint: DrawingPoint(x: 90, y: 80),
      style: style,
    );
    final text = TextElement.create(text: 'My notebook', x: 20, y: 120);
    final image = ImageElement.create(
        filePath: 'images/a.png', x: 100, y: 100, width: 40, height: 30);
    final note = StickyNote.create(x: 150, y: 150);
    final cover = Page.createCover(
      index: 0,
      background: const PageBackground(
        type: BackgroundType.cover,
        color: 0xFF1E3A5F,
        coverId: 'classic_blue',
      ),
    );
    final layer = cover.layers.first.copyWith(
      strokes: [stroke],
      shapes: [shape],
      texts: [text],
      images: [image],
      stickyNotes: [note],
      elementOrder: [stroke.id, shape.id, text.id, image.id, note.id],
    );
    return cover.copyWith(layers: [layer]);
  }

  test('ink, shapes and text on the cover survive save and load', () async {
    final cover = coverWithEverything();
    final doc = DrawingDocument.multiPage(
      id: 'doc',
      title: 'Notebook',
      pages: [cover, Page.create(index: 1)],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    final saved = await SaveDocumentUseCase(repository)(doc);
    expect(saved.isRight(), isTrue);

    final loaded = await LoadDocumentUseCase(repository)('doc');
    final page = loaded.getOrElse(() => throw StateError('load failed')).pages[0];

    expect(page.isCover, isTrue);
    final layer = page.layers.single;
    final original = cover.layers.single;
    expect(layer.strokes, hasLength(1));
    expect(layer.shapes, hasLength(1));
    expect(layer.texts, hasLength(1));
    expect(layer.images, hasLength(1));
    expect(layer.stickyNotes, hasLength(1));
    expect(layer.toJson(), original.toJson());
    expect(page.background.coverId, 'classic_blue');
  });
}
