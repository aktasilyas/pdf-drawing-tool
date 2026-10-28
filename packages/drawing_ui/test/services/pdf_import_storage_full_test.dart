import 'dart:async';
import 'dart:io';

import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// No space left on device, as `File.copy` reports it on Android/Linux.
FileSystemException noSpace(String path) => FileSystemException(
      'Cannot copy file',
      path,
      const OSError('No space left on device', 28),
    );

/// A real file whose [copy] writes part of the data and then hits ENOSPC.
class _NoSpaceSource implements File {
  _NoSpaceSource(this._real);

  final File _real;

  @override
  String get path => _real.path;

  @override
  Future<File> copy(String newPath) async {
    await Zone.root.run(() => File(newPath)).writeAsBytes([1, 2]);
    throw noSpace(newPath);
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      _real.open(mode: mode);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pdfImportFailureFor', () {
    test('maps errno 28 to storageFull', () {
      expect(
        pdfImportFailureFor(noSpace('/x.pdf')).error,
        PdfImportError.storageFull,
      );
    });

    test('maps a "No space left" message without errno to storageFull', () {
      const error = FileSystemException('No space left on device', '/x.pdf');
      expect(pdfImportFailureFor(error).error, PdfImportError.storageFull);
    });

    test('maps other file system errors to fileAccess', () {
      const error = FileSystemException(
        'Cannot open file',
        '/x.pdf',
        OSError('Permission denied', 13),
      );
      expect(pdfImportFailureFor(error).error, PdfImportError.fileAccess);
    });
  });

  group('importFromFile on a full disk', () {
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

    test('reports storageFull and leaves no partial copy', () async {
      final source = File('${src.path}/a.pdf')..writeAsBytesSync([1, 2, 3]);
      final service = PDFImportService(
        loader: PDFLoader(openFile: (_) async => throw StateError('unused')),
      );
      addTearDown(service.dispose);

      final result = await IOOverrides.runZoned(
        () => service.importFromFile(
          filePath: source.path,
          config: PDFImportConfig.all(),
        ),
        createFile: (path) {
          final real = Zone.root.run(() => File(path));
          return path == source.path ? _NoSpaceSource(real) : real;
        },
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure?.error, PdfImportError.storageFull);
      final stored = Directory('${docs.path}/pdfs');
      expect(stored.existsSync() ? stored.listSync() : [], isEmpty);
    });
  });
}
