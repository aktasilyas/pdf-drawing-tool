import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late Directory src;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('pdf_docs');
    src = Directory.systemTemp.createTempSync('pdf_src');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => docs.path,
    );
  });

  tearDown(() {
    docs.deleteSync(recursive: true);
    src.deleteSync(recursive: true);
  });

  List<FileSystemEntity> stored() {
    final dir = Directory('${docs.path}/pdfs');
    return dir.existsSync() ? dir.listSync() : [];
  }

  Future<PDFImportServiceResult> importWith(Object error) async {
    final file = File('${src.path}/a.pdf')..writeAsBytesSync([1, 2, 3]);
    final service = PDFImportService(
      loader: PDFLoader(openFile: (_) async => throw error),
    );
    addTearDown(service.dispose);
    return service.importFromFile(
      filePath: file.path,
      config: PDFImportConfig.all(),
    );
  }

  test('password-protected PDF gives a friendly message and no leftover',
      () async {
    final r = await importWith(
      PlatformException(code: 'pdf', message: 'Password required'),
    );
    expect(r.isSuccess, isFalse);
    expect(r.errorMessage, contains('parola korumalı'));
    expect(r.errorMessage, isNot(contains('PlatformException')));
    expect(stored(), isEmpty);
  });

  test('corrupt PDF gives a friendly message and no leftover', () async {
    final r = await importWith(
      PlatformException(code: 'pdf', message: 'bad xref'),
    );
    expect(r.errorMessage, contains('bozuk'));
    expect(r.errorMessage, isNot(contains('PlatformException')));
    expect(stored(), isEmpty);
  });
}
