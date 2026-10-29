import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  late Directory root;
  late Directory incoming;
  late LocalPdfSourceFiles files;
  late File picked;

  setUp(() {
    root = Directory.systemTemp.createTempSync('relink_root');
    incoming = Directory.systemTemp.createTempSync('relink_in');
    files = LocalPdfSourceFiles(PdfPathResolver(root.path));
    picked = File('${incoming.path}/b.pdf')..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() {
    root.deleteSync(recursive: true);
    incoming.deleteSync(recursive: true);
  });

  List<String> tempFiles() => root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.tmp'))
      .map((f) => f.path)
      .toList();

  test('copies the bytes to the resolved path and creates pdfs/', () async {
    expect(await files.exists('pdfs/a.pdf'), isFalse);

    final result = await files.install(picked.path, 'pdfs/a.pdf');

    expect(result, const Right<Failure, Unit>(unit));
    expect(File('${root.path}/pdfs/a.pdf').readAsBytesSync(), [1, 2, 3]);
    expect(await files.exists('pdfs/a.pdf'), isTrue);
    expect(tempFiles(), isEmpty);
  });

  test('never overwrites an existing target', () async {
    final target = File('${root.path}/pdfs/a.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync([9, 9]);

    final result = await files.install(picked.path, 'pdfs/a.pdf');

    expect(
      result,
      const Left<Failure, Unit>(PdfRelinkFailure(PdfRelinkError.targetExists)),
    );
    expect(target.readAsBytesSync(), [9, 9]);
    expect(tempFiles(), isEmpty);
  });

  test('a missing source gives fileAccess and leaves no temp file', () async {
    final result = await files.install(
      '${incoming.path}/nope.pdf',
      'pdfs/a.pdf',
    );

    expect(
      result,
      const Left<Failure, Unit>(PdfRelinkFailure(PdfRelinkError.fileAccess)),
    );
    expect(File('${root.path}/pdfs/a.pdf').existsSync(), isFalse);
    expect(tempFiles(), isEmpty);
  });

  test('a legacy absolute stored path lands under the current root', () async {
    const legacy = '/data/user/0/old.app/app_flutter/pdfs/old.pdf';

    final result = await files.install(picked.path, legacy);

    expect(result, const Right<Failure, Unit>(unit));
    expect(File('${root.path}/pdfs/old.pdf').readAsBytesSync(), [1, 2, 3]);
    expect(await files.exists(legacy), isTrue);
  });
}
