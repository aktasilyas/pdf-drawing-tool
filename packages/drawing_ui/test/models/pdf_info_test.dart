import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/models/pdf_info.dart';

void main() {
  group('PDFInfo', () {
    group('Constructor', () {
      test('should create with all parameters', () {
        final creationDate = DateTime(2024, 1, 1);
        final modDate = DateTime(2024, 1, 2);

        final info = PDFInfo(
          pageCount: 10,
          title: 'Test PDF',
          author: 'Test Author',
          subject: 'Test Subject',
          keywords: 'test, pdf',
          creator: 'Test Creator',
          producer: 'Test Producer',
          creationDate: creationDate,
          modificationDate: modDate,
          fileSizeBytes: 1024,
        );

        expect(info.pageCount, 10);
        expect(info.title, 'Test PDF');
        expect(info.author, 'Test Author');
        expect(info.subject, 'Test Subject');
        expect(info.keywords, 'test, pdf');
        expect(info.creator, 'Test Creator');
        expect(info.producer, 'Test Producer');
        expect(info.creationDate, creationDate);
        expect(info.modificationDate, modDate);
        expect(info.fileSizeBytes, 1024);
      });

      test('should create with only required parameters', () {
        final info = PDFInfo(pageCount: 5);

        expect(info.pageCount, 5);
        expect(info.title, null);
        expect(info.author, null);
        expect(info.subject, null);
        expect(info.keywords, null);
        expect(info.creator, null);
        expect(info.producer, null);
        expect(info.creationDate, null);
        expect(info.modificationDate, null);
        expect(info.fileSizeBytes, null);
      });

      test('should create minimal info', () {
        final info = PDFInfo.minimal(3);

        expect(info.pageCount, 3);
        expect(info.title, null);
        expect(info.author, null);
      });
    });

    group('copyWith', () {
      test('should copy with new page count', () {
        final original = PDFInfo(pageCount: 10, title: 'Original');
        final copy = original.copyWith(pageCount: 20);

        expect(copy.pageCount, 20);
        expect(copy.title, 'Original');
      });

      test('should copy with new title', () {
        final original = PDFInfo(pageCount: 10, title: 'Original');
        final copy = original.copyWith(title: 'Updated');

        expect(copy.pageCount, 10);
        expect(copy.title, 'Updated');
      });

      test('should copy with multiple new values', () {
        final original = PDFInfo(
          pageCount: 10,
          title: 'Original',
          author: 'Original Author',
        );

        final copy = original.copyWith(
          title: 'Updated',
          author: 'Updated Author',
          subject: 'New Subject',
        );

        expect(copy.pageCount, 10);
        expect(copy.title, 'Updated');
        expect(copy.author, 'Updated Author');
        expect(copy.subject, 'New Subject');
      });

      test('should keep original values when not specified', () {
        final creationDate = DateTime(2024, 1, 1);
        final original = PDFInfo(
          pageCount: 10,
          title: 'Test',
          creationDate: creationDate,
        );

        final copy = original.copyWith(author: 'New Author');

        expect(copy.pageCount, 10);
        expect(copy.title, 'Test');
        expect(copy.author, 'New Author');
        expect(copy.creationDate, creationDate);
      });
    });

    group('Equality', () {
      test('should be equal when all fields match', () {
        final date = DateTime(2024, 1, 1);

        final info1 = PDFInfo(
          pageCount: 10,
          title: 'Test',
          author: 'Author',
          creationDate: date,
        );

        final info2 = PDFInfo(
          pageCount: 10,
          title: 'Test',
          author: 'Author',
          creationDate: date,
        );

        expect(info1, equals(info2));
        expect(info1.hashCode, equals(info2.hashCode));
      });

      test('should not be equal when page count differs', () {
        final info1 = PDFInfo(pageCount: 10);
        final info2 = PDFInfo(pageCount: 20);

        expect(info1, isNot(equals(info2)));
      });

      test('should not be equal when title differs', () {
        final info1 = PDFInfo(pageCount: 10, title: 'Test1');
        final info2 = PDFInfo(pageCount: 10, title: 'Test2');

        expect(info1, isNot(equals(info2)));
      });

      test('should not be equal when author differs', () {
        final info1 = PDFInfo(pageCount: 10, author: 'Author1');
        final info2 = PDFInfo(pageCount: 10, author: 'Author2');

        expect(info1, isNot(equals(info2)));
      });

      test('should handle null values in equality', () {
        final info1 = PDFInfo(pageCount: 10, title: 'Test');
        final info2 = PDFInfo(pageCount: 10, title: 'Test', author: null);

        expect(info1, equals(info2));
      });
    });

    group('toString', () {
      test('should include key information', () {
        final info = PDFInfo(
          pageCount: 10,
          title: 'Test PDF',
          author: 'Test Author',
        );

        final str = info.toString();

        expect(str, contains('10'));
        expect(str, contains('Test PDF'));
        expect(str, contains('Test Author'));
      });

      test('should handle null values', () {
        final info = PDFInfo(pageCount: 5);

        final str = info.toString();

        expect(str, contains('5'));
        expect(str, contains('null'));
      });
    });

    group('Edge Cases', () {
      test('should handle zero pages', () {
        final info = PDFInfo(pageCount: 0);
        expect(info.pageCount, 0);
      });

      test('should handle very large page count', () {
        final info = PDFInfo(pageCount: 999999);
        expect(info.pageCount, 999999);
      });

      test('should handle empty strings', () {
        final info = PDFInfo(
          pageCount: 1,
          title: '',
          author: '',
        );

        expect(info.title, '');
        expect(info.author, '');
      });

      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        final info = PDFInfo(
          pageCount: 1,
          title: longString,
        );

        expect(info.title, longString);
      });

      test('should handle dates at boundaries', () {
        final minDate = DateTime(1900, 1, 1);
        final maxDate = DateTime(2100, 12, 31);

        final info = PDFInfo(
          pageCount: 1,
          creationDate: minDate,
          modificationDate: maxDate,
        );

        expect(info.creationDate, minDate);
        expect(info.modificationDate, maxDate);
      });

      test('should handle large file sizes', () {
        final largeSize = 1024 * 1024 * 1024 * 2; // 2 GB
        final info = PDFInfo(
          pageCount: 1,
          fileSizeBytes: largeSize,
        );

        expect(info.fileSizeBytes, largeSize);
      });
    });
  });
}
