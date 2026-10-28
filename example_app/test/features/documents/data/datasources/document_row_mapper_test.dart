import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/datasources/document_row_mapper.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('every field survives model -> companion -> row -> model', () async {
    final model = DocumentModel(
      id: 'doc-1',
      title: 'Notes',
      folderId: 'folder-1',
      templateId: 'grid',
      createdAt: DateTime(2026, 1, 2, 3, 4, 5),
      updatedAt: DateTime(2026, 2, 3, 4, 5, 6),
      thumbnailPath: 'thumbs/doc-1.png',
      pageCount: 7,
      isFavorite: true,
      isInTrash: true,
      deletedAt: DateTime(2026, 3, 4, 5, 6, 7),
      syncState: 2,
      paperColor: 'Beyaz kağıt',
      isPortrait: false,
      documentType: 'pdf',
      coverId: 'cover-3',
      hasCover: false,
      paperWidthMm: 148,
      paperHeightMm: 210,
    );

    await db.into(db.documents).insert(model.toCompanion());
    final row = await db.select(db.documents).getSingle();

    expect(row.toModel().toJson(), model.toJson());
  });
}
