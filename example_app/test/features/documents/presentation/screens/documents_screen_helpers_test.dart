import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';

import 'library_fixtures.dart';

void main() {
  group('resolveNewFolderParent', () {
    test('null current folder creates at the root', () {
      final target = resolveNewFolderParent(null, libraryFolders);
      expect(target.parentId, isNull);
      expect(target.depthExceeded, isFalse);
    });

    test('inside a root folder the new folder becomes its subfolder', () {
      final target = resolveNewFolderParent('f-ders', libraryFolders);
      expect(target.parentId, 'f-ders');
      expect(target.depthExceeded, isFalse);
    });

    test('inside a subfolder the depth limit is reported', () {
      final target = resolveNewFolderParent('f-biyoloji', libraryFolders);
      expect(target.parentId, isNull);
      expect(target.depthExceeded, isTrue);
    });

    test('unknown folder id falls back to the root', () {
      final target = resolveNewFolderParent('missing', libraryFolders);
      expect(target.parentId, isNull);
      expect(target.depthExceeded, isFalse);
    });

    test('empty folder list falls back to the root', () {
      final target = resolveNewFolderParent('f-ders', const []);
      expect(target.parentId, isNull);
      expect(target.depthExceeded, isFalse);
    });
  });
}
