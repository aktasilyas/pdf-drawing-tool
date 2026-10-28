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

  Future<PDFImportServiceResult> importWith(
    Object error, {
    List<int> bytes = const [1, 2, 3],
  }) async {
    final file = File('${src.path}/a.pdf')..writeAsBytesSync(bytes);
    final service = PDFImportService(
      loader: PDFLoader(openFile: (_) async => throw error),
    );
    addTearDown(service.dispose);
    return service.importFromFile(
      filePath: file.path,
      config: PDFImportConfig.all(),
    );
  }

  test('password-protected PDF gives a typed failure and no leftover',
      () async {
    final r = await importWith(
      PlatformException(code: 'pdf', message: 'Password required'),
    );
    expect(r.isSuccess, isFalse);
    expect(r.failure?.error, PdfImportError.passwordProtected);
    expect(stored(), isEmpty);
  });

  test('corrupt PDF gives a typed failure and no leftover', () async {
    final r = await importWith(
      PlatformException(code: 'pdf', message: 'bad xref'),
    );
    expect(r.failure?.error, PdfImportError.openFailed);
    expect(stored(), isEmpty);
  });

  test('encrypted PDF: password message despite a generic error', () async {
    final encrypted = '%PDF-1.7\ntrailer << /Encrypt 5 0 R >>'.codeUnits;
    final r = await importWith(
      PlatformException(code: 'PDF_RENDER', message: "Can't open file"),
      bytes: encrypted,
    );
    expect(r.isSuccess, isFalse);
    expect(r.failure?.error, PdfImportError.passwordProtected);
    expect(stored(), isEmpty);
  });

  group('pdfFileLooksEncrypted', () {
    Future<bool> sniff(List<int> bytes) {
      final file = File('${src.path}/s.pdf')..writeAsBytesSync(bytes);
      return pdfFileLooksEncrypted(file.path);
    }

    test('finds /Encrypt in the trailer', () async {
      final hit = await sniff('%PDF-1.4 << /Encrypt 3 0 R >>'.codeUnits);
      expect(hit, isTrue);
    });

    test('is false for a plain PDF and for a missing file', () async {
      final miss = await sniff('%PDF-1.4 << /Root 1 0 R >>'.codeUnits);
      expect(miss, isFalse);
      expect(await pdfFileLooksEncrypted('${src.path}/missing.pdf'), isFalse);
    });
  });
}
