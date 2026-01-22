import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  group('Folder', () {
    final testFolder = Folder(
      id: 'folder-1',
      name: 'Test Folder',
      createdAt: DateTime(2024, 1, 1),
    );

    test('should have correct default values', () {
      expect(testFolder.colorValue, 0xFF2196F3);
      expect(testFolder.documentCount, 0);
      expect(testFolder.parentId, null);
    });

    test('should correctly identify root folder', () {
      final rootFolder = Folder(
        id: 'root',
        name: 'Root',
        createdAt: DateTime.now(),
      );

      final childFolder = Folder(
        id: 'child',
        name: 'Child',
        parentId: 'root',
        createdAt: DateTime.now(),
      );

      expect(rootFolder.isRoot, true);
      expect(childFolder.isRoot, false);
    });

    test('should support value equality', () {
      final folder1 = Folder(
        id: 'folder-1',
        name: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );

      final folder2 = Folder(
        id: 'folder-1',
        name: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(folder1, folder2);
    });

    test('should support copyWith', () {
      final updated = testFolder.copyWith(
        name: 'Updated Name',
        colorValue: 0xFFFF0000,
      );

      expect(updated.name, 'Updated Name');
      expect(updated.colorValue, 0xFFFF0000);
      expect(updated.id, testFolder.id);
      expect(updated.createdAt, testFolder.createdAt);
    });
  });
}
