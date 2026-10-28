import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/image_import_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late File source;

  setUp(() {
    root = Directory.systemTemp.createTempSync('img_store_test');
    source = File('${root.path}/picked.png')..writeAsBytesSync([1, 2, 3]);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('stores a container-relative path and copies the file', () async {
    final stored = await storeImportedImage(
      source.path,
      documentsRoot: root.path,
      paths: PdfPathResolver(root.path),
    );

    expect(stored, matches(RegExp(r'^elyanotes_images/\d+\.png$')));
    expect(File('${root.path}/$stored').readAsBytesSync(), [1, 2, 3]);
  });

  test('without a resolver the absolute path is returned', () async {
    final stored =
        await storeImportedImage(source.path, documentsRoot: root.path);

    expect(stored, startsWith('${root.path}/elyanotes_images/'));
    expect(File(stored).existsSync(), isTrue);
  });

  test('a missing source throws and leaves no file behind', () async {
    await expectLater(
      storeImportedImage('${root.path}/nope.png', documentsRoot: root.path),
      throwsA(isA<FileSystemException>()),
    );
    final dir = Directory('${root.path}/elyanotes_images');
    expect(dir.existsSync() ? dir.listSync() : [], isEmpty);
  });
}
