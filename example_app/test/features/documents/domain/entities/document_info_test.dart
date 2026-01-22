import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  group('DocumentInfo', () {
    final testDocument = DocumentInfo(
      id: 'doc-1',
      title: 'Test Document',
      templateId: 'blank',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should have correct default values', () {
      expect(testDocument.pageCount, 1);
      expect(testDocument.isFavorite, false);
      expect(testDocument.isInTrash, false);
      expect(testDocument.syncState, SyncState.local);
    });

    test('should support value equality', () {
      final document1 = DocumentInfo(
        id: 'doc-1',
        title: 'Test',
        templateId: 'blank',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final document2 = DocumentInfo(
        id: 'doc-1',
        title: 'Test',
        templateId: 'blank',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(document1, document2);
    });

    test('should support copyWith', () {
      final updated = testDocument.copyWith(
        title: 'Updated Title',
        pageCount: 5,
      );

      expect(updated.title, 'Updated Title');
      expect(updated.pageCount, 5);
      expect(updated.id, testDocument.id);
      expect(updated.templateId, testDocument.templateId);
    });

    test('should have different hash codes for different documents', () {
      final document2 = testDocument.copyWith(id: 'doc-2');
      expect(testDocument.hashCode, isNot(document2.hashCode));
    });
  });
}
