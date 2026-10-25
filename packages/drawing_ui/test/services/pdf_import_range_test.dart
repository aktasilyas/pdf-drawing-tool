import 'dart:typed_data';

import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoader extends Mock implements PDFLoader {}

void main() {
  setUpAll(() => registerFallbackValue(Uint8List(0)));

  test('importFromBytes rejects startPage > endPage before loading', () async {
    final loader = _MockLoader();
    final service = PDFImportService(loader: loader);

    await expectLater(
      service.importFromBytes(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        config: PDFImportConfig.pageRange(startPage: 10, endPage: 1),
      ),
      throwsArgumentError,
    );

    verifyNever(() => loader.loadFromFile(any()));
    verifyNever(() => loader.loadFromBytes(any()));
    service.dispose();
  });
}
