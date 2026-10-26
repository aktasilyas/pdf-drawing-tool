import 'dart:io';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_import_pages.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_import_storage.dart';
import 'package:drawing_ui/src/services/pdf_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory docs;
  late Directory src;
  late PdfPathResolver resolver;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('pdf_docs_');
    src = Directory.systemTemp.createTempSync('pdf_src_');
    resolver = PdfPathResolver(docs.path);
  });

  tearDown(() {
    docs.deleteSync(recursive: true);
    src.deleteSync(recursive: true);
  });

  List<FileSystemEntity> stored() {
    final dir = Directory('${docs.path}/pdfs');
    return dir.existsSync() ? dir.listSync() : [];
  }

  group('newImportedPdfFile', () {
    test('builds the file under <root>/pdfs without path_provider', () async {
      final file = await newImportedPdfFile(resolver);

      expect(file.path, startsWith('${docs.path}/pdfs/pdf_'));
      expect(resolver.toStored(file.path), startsWith('pdfs/'));
    });
  });

  group('storePdfAndImport', () {
    test('a copy that writes bytes and then throws leaves pdfs/ empty',
        () async {
      final file = await newImportedPdfFile(resolver);

      await expectLater(
        storePdfAndImport<int>(
          file: file,
          write: (f) async {
            await f.writeAsBytes([1, 2, 3]);
            throw const FileSystemException('disk full');
          },
          import: (_) async => 1,
          isFailure: (_) => false,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(stored(), isEmpty);
    });

    test('a throwing import leaves pdfs/ empty', () async {
      final file = await newImportedPdfFile(resolver);

      await expectLater(
        storePdfAndImport<int>(
          file: file,
          write: (f) => f.writeAsBytes([1]),
          import: (_) async => throw StateError('boom'),
          isFailure: (_) => false,
        ),
        throwsStateError,
      );

      expect(stored(), isEmpty);
    });

    test('a failed result leaves pdfs/ empty', () async {
      final file = await newImportedPdfFile(resolver);

      final result = await storePdfAndImport<bool>(
        file: file,
        write: (f) => f.writeAsBytes([1]),
        import: (_) async => false,
        isFailure: (ok) => !ok,
      );

      expect(result, isFalse);
      expect(stored(), isEmpty);
    });

    test('success keeps the file and the stored path is relative', () async {
      final file = await newImportedPdfFile(resolver);

      final storedPath = await storePdfAndImport<String>(
        file: file,
        write: (f) => f.writeAsBytes([1]),
        import: (f) async => resolver.toStored(f.path),
        isFailure: (_) => false,
      );

      expect(storedPath, startsWith('pdfs/'));
      expect(stored(), hasLength(1));
      expect(File(resolver.resolve(storedPath)).existsSync(), isTrue);
    });
  });

  group('PDFImportService with a documents root', () {
    test('a missing source file fails the copy and leaves pdfs/ empty',
        () async {
      final service = PDFImportService(
        loader: PDFLoader(openFile: (_) async => throw StateError('unused')),
        pdfPaths: resolver,
      );
      addTearDown(service.dispose);

      final result = await service.importFromFile(
        filePath: '${src.path}/missing.pdf',
        config: PDFImportConfig.all(),
      );

      expect(result.isSuccess, isFalse);
      expect(stored(), isEmpty);
    });

    test('a loader failure after a successful copy leaves pdfs/ empty',
        () async {
      final source = File('${src.path}/a.pdf')..writeAsBytesSync([1, 2, 3]);
      final service = PDFImportService(
        loader: PDFLoader(openFile: (_) async => throw StateError('bad pdf')),
        pdfPaths: resolver,
      );
      addTearDown(service.dispose);

      final result = await service.importFromFile(
        filePath: source.path,
        config: PDFImportConfig.all(),
      );

      expect(result.isSuccess, isFalse);
      expect(stored(), isEmpty);
    });

    test('importFromBytes with a failing loader leaves pdfs/ empty', () async {
      final service = PDFImportService(
        loader: PDFLoader(openFile: (_) async => throw StateError('bad pdf')),
        pdfPaths: resolver,
      );
      addTearDown(service.dispose);

      final result = await service.importFromBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        config: PDFImportConfig.all(),
      );

      expect(result.isSuccess, isFalse);
      expect(stored(), isEmpty);
    });
  });
}
