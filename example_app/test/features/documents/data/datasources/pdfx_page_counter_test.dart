import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:drawing_ui/drawing_ui.dart' show PDFLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

// Note: the success path needs a pdfx PdfDocument fake; pdfx is not a direct
// dependency of example_app, so only the failure mapping is covered here.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('relink_count'));
  tearDown(() => dir.deleteSync(recursive: true));

  PdfxPageCounter counterFailingToOpen() => PdfxPageCounter(
        loader: PDFLoader(
          openFile: (_) async => throw StateError('cannot open'),
        ),
      );

  Future<Either<Failure, int>> count(String content) {
    final file = File('${dir.path}/x.pdf')..writeAsStringSync(content);
    return counterFailingToOpen().pageCount(file.path);
  }

  test('a failing open on an /Encrypt file is passwordProtected', () async {
    expect(
      await count('%PDF-1.7 trailer << /Encrypt 5 0 R >>'),
      const Left<Failure, int>(
        PdfRelinkFailure(PdfRelinkError.passwordProtected),
      ),
    );
  });

  test('a failing open on a plain file is openFailed', () async {
    expect(
      await count('%PDF-1.7 trailer << >>'),
      const Left<Failure, int>(PdfRelinkFailure(PdfRelinkError.openFailed)),
    );
  });

  test('a missing file is openFailed', () async {
    expect(
      await counterFailingToOpen().pageCount('${dir.path}/missing.pdf'),
      const Left<Failure, int>(PdfRelinkFailure(PdfRelinkError.openFailed)),
    );
  });
}
