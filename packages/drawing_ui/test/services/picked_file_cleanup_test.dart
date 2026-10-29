import 'dart:io';

import 'package:drawing_ui/src/services/picked_file_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late Directory cache;

  setUp(() {
    root = Directory.systemTemp.createTempSync('picked_cleanup_test');
    cache = Directory('${root.path}/cache')..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<void> cleanup(String path) =>
      deletePickedFileCopy(path, cacheDirectory: () async => cache.path);

  File fileAt(String path) => File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync('%PDF-1.4');

  group('deletePickedFileCopy', () {
    test('deletes a picker copy inside the cache directory', () async {
      final copy = fileAt('${cache.path}/file_picker/123/a.pdf');

      await cleanup(copy.path);

      expect(copy.existsSync(), isFalse);
    });

    test('never deletes a file outside the cache directory', () async {
      final original = fileAt('${root.path}/Documents/a.pdf');

      await cleanup(original.path);

      expect(original.existsSync(), isTrue);
    });

    test('keeps a sibling whose name starts with the cache name', () async {
      final sibling = fileAt('${root.path}/cache2/a.pdf');

      await cleanup(sibling.path);

      expect(sibling.existsSync(), isTrue);
    });

    test('keeps a file reached by escaping the cache with ..', () async {
      final outside = fileAt('${root.path}/outside.pdf');

      await cleanup('${cache.path}/../outside.pdf');

      expect(outside.existsSync(), isTrue);
    });

    test('a missing file or unknown cache directory does not throw',
        () async {
      await cleanup('${cache.path}/gone.pdf');
      await deletePickedFileCopy(
        '${cache.path}/a.pdf',
        cacheDirectory: () async => throw StateError('no cache'),
      );
    });
  });

  group('isPathInsideDirectory', () {
    test('only strict descendants are inside', () {
      final c = cache.path;
      expect(isPathInsideDirectory('$c/a.pdf', c), isTrue);
      expect(isPathInsideDirectory('$c/a.pdf', '$c/'), isTrue);
      expect(isPathInsideDirectory(c, c), isFalse);
      expect(isPathInsideDirectory('$c/../a.pdf', c), isFalse);
      expect(isPathInsideDirectory('${c}2/a.pdf', c), isFalse);
    });
  });

  group('withPickedFile', () {
    test('a successful import keeps its stored copy and drops the temp file',
        () async {
      final picked = fileAt('${cache.path}/file_picker/1/in.pdf');
      final stored = File('${root.path}/pdfs/stored.pdf');

      final result = await withPickedFile(
        picked.path,
        () async {
          stored.parent.createSync(recursive: true);
          await picked.copy(stored.path);
          return 'done';
        },
        cleanup: cleanup,
      );

      expect(result, 'done');
      expect(picked.existsSync(), isFalse);
      expect(stored.existsSync(), isTrue);
    });

    test('a failed import drops the temp file and rethrows', () async {
      final picked = fileAt('${cache.path}/file_picker/2/in.pdf');

      await expectLater(
        withPickedFile<void>(
          picked.path,
          () async => throw const FileSystemException('disk full'),
          cleanup: cleanup,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(picked.existsSync(), isFalse);
    });
  });
}
