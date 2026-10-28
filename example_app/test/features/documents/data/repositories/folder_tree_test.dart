import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/documents/data/repositories/folder_tree.dart';

FolderModel _folder(String id, {String? parentId}) => FolderModel(
      id: id,
      name: id,
      parentId: parentId,
      createdAt: DateTime(2024),
    );

void main() {
  group('FolderTree.descendantIds', () {
    final all = [
      _folder('a'),
      _folder('b', parentId: 'a'),
      _folder('c', parentId: 'b'),
      _folder('d'),
    ];

    test('collects children recursively', () {
      expect(FolderTree.descendantIds('a', all), {'b', 'c'});
    });

    test('leaf and unrelated folders have none', () {
      expect(FolderTree.descendantIds('c', all), isEmpty);
      expect(FolderTree.descendantIds('d', all), isEmpty);
    });
  });
}
