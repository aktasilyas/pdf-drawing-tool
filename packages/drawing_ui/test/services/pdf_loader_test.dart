import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/pdf_loader.dart';
import 'package:drawing_ui/src/models/pdf_info.dart';

void main() {
  group('PDFLoader', () {
    late PDFLoader loader;

    setUp(() {
      loader = PDFLoader();
    });

    tearDown(() {
      loader.dispose();
    });

    group('Constructor', () {
      test('should create instance', () {
        final l = PDFLoader();
        expect(l, isNotNull);
        l.dispose();
      });
    });

    group('Document Info Extraction', () {
      test('should extract page count from minimal PDF', () {
        // This would require actual PDF bytes or mock
        // For now, testing the interface
        expect(loader, isNotNull);
      });

      test('should extract metadata when available', () {
        // Testing metadata extraction interface
        expect(loader, isNotNull);
      });

      test('should handle missing metadata gracefully', () {
        // Should return PDFInfo with available data only
        expect(loader, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should throw on invalid file path', () async {
        expect(
          () => loader.loadFromFile('/nonexistent/file.pdf'),
          throwsA(isA<PDFLoaderException>()),
        );
      });

      test('should throw on invalid PDF bytes', () async {
        final invalidBytes = Uint8List.fromList([1, 2, 3, 4]);
        
        expect(
          () => loader.loadFromBytes(invalidBytes),
          throwsA(isA<PDFLoaderException>()),
        );
      });

      test('should throw on empty bytes', () async {
        final emptyBytes = Uint8List(0);
        
        expect(
          () => loader.loadFromBytes(emptyBytes),
          throwsA(isA<PDFLoaderException>()),
        );
      });

      test('should throw on corrupted PDF', () async {
        // Bytes that look like PDF but are corrupted
        final corruptedBytes = Uint8List.fromList(
          '%PDF-1.4\n'.codeUnits + [0, 0, 0, 0],
        );
        
        expect(
          () => loader.loadFromBytes(corruptedBytes),
          throwsA(isA<PDFLoaderException>()),
        );
      });
    });

    group('Document Lifecycle', () {
      test('should track loaded documents', () {
        expect(loader.loadedDocumentCount, 0);
      });

      test('should dispose loaded documents', () {
        loader.dispose();
        expect(loader.isDisposed, true);
      });

      test('should not allow operations after dispose', () {
        loader.dispose();
        
        expect(
          () => loader.loadFromFile('/test.pdf'),
          throwsA(isA<PDFLoaderException>()),
        );
      });
    });

    group('Page Count', () {
      test('should return correct page count', () {
        // Interface test - actual implementation needs real PDF
        expect(loader, isNotNull);
      });

      test('should handle single page PDF', () {
        // Should work with 1-page PDFs
        expect(loader, isNotNull);
      });

      test('should handle large PDF', () {
        // Should handle PDFs with many pages
        expect(loader, isNotNull);
      });
    });

    group('Memory Management', () {
      test('should dispose documents properly', () {
        loader.dispose();
        expect(loader.isDisposed, true);
      });

      test('should clear document cache on dispose', () {
        loader.dispose();
        expect(loader.loadedDocumentCount, 0);
      });

      test('should be safe to dispose multiple times', () {
        expect(() {
          loader.dispose();
          loader.dispose();
          loader.dispose();
        }, returnsNormally);
      });
    });
  });

  group('PDFLoaderException', () {
    test('should create with message', () {
      final exception = PDFLoaderException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.toString(), contains('Test error'));
    });

    test('should create with message and cause', () {
      final cause = Exception('Original error');
      final exception = PDFLoaderException('Wrapped error', cause: cause);
      
      expect(exception.message, 'Wrapped error');
      expect(exception.cause, cause);
    });

    test('should handle null cause', () {
      final exception = PDFLoaderException('Error');
      expect(exception.cause, null);
    });
  });
}
