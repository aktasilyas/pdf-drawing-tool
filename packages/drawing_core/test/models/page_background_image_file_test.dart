import 'dart:convert';
import 'dart:typed_data';

import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

  group('image file reference', () {
    test('toJson writes imageFilePath and no inline bytes', () {
      final bg = PageBackground(
        type: BackgroundType.pdf,
        pdfPageIndex: 1,
        imageFilePath: 'elyanotes_images/1.png',
        pdfData: bytes,
      );
      final json = bg.toJson();
      expect(json['imageFilePath'], 'elyanotes_images/1.png');
      expect(json.containsKey('pdfDataBase64'), isFalse);
      expect(bg.isImage, isTrue);
    });

    test('fromJson round-trips the reference; bytes are not restored', () {
      final bg = PageBackground(
        type: BackgroundType.pdf,
        pdfPageIndex: 1,
        imageFilePath: 'elyanotes_images/1.png',
        pdfData: bytes,
      );
      final back = PageBackground.fromJson(bg.toJson());
      expect(back.imageFilePath, 'elyanotes_images/1.png');
      expect(back.pdfData, isNull);
      expect(back.isImage, isTrue);
    });

    test('legacy inline-bytes JSON decodes and re-encodes identically', () {
      final legacy = {
        'type': 'pdf',
        'color': 0xFFFFFFFF,
        'pdfPageIndex': 1,
        'pdfDataBase64': base64Encode(bytes),
      };
      final bg = PageBackground.fromJson(legacy);
      expect(bg.pdfData, bytes);
      expect(bg.imageFilePath, isNull);
      expect(bg.isImage, isTrue);
      expect(bg.toJson(), legacy);
    });

    test('pdfFilePath JSON is unchanged (lazy PDF)', () {
      final bg =
          PageBackground.pdfLazy(pageIndex: 2, pdfFilePath: 'pdfs/a.pdf');
      final json = bg.toJson();
      expect(json['pdfFilePath'], 'pdfs/a.pdf');
      expect(json.containsKey('imageFilePath'), isFalse);
      expect(json.containsKey('pdfDataBase64'), isFalse);
      expect(bg.isImage, isFalse);
      expect(PageBackground.fromJson(json), bg);
    });

    test('copyWith, equality and hashCode include imageFilePath', () {
      const a = PageBackground(
          type: BackgroundType.pdf, imageFilePath: 'elyanotes_images/a.png');
      final b = a.copyWith(imageFilePath: 'elyanotes_images/b.png');
      expect(b.imageFilePath, 'elyanotes_images/b.png');
      expect(a, isNot(b));
      expect(a, a.copyWith());
      expect(a.hashCode, a.copyWith().hashCode);
    });
  });
}
