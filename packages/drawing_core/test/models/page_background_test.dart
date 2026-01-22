import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PageBackground', () {
    test('should create blank background', () {
      expect(PageBackground.blank.type, BackgroundType.blank);
      expect(PageBackground.blank.color, 0xFFFFFFFF);
    });

    test('should create grid background', () {
      expect(PageBackground.grid.type, BackgroundType.grid);
      expect(PageBackground.grid.gridSpacing, 20);
    });

    test('should create lined background', () {
      expect(PageBackground.lined.type, BackgroundType.lined);
      expect(PageBackground.lined.lineSpacing, 24);
    });

    test('should create PDF background', () {
      final pdfData = Uint8List.fromList([1, 2, 3]);
      final bg = PageBackground.pdf(pdfData: pdfData, pageIndex: 0);
      expect(bg.type, BackgroundType.pdf);
      expect(bg.pdfPageIndex, 0);
      expect(bg.pdfData, pdfData);
    });

    test('should serialize to JSON', () {
      final json = PageBackground.grid.toJson();
      expect(json['type'], 'grid');
      expect(json['gridSpacing'], 20);
    });

    test('should deserialize from JSON', () {
      final json = {'type': 'grid', 'color': 0xFFFFFFFF, 'gridSpacing': 20.0};
      final bg = PageBackground.fromJson(json);
      expect(bg.type, BackgroundType.grid);
      expect(bg.gridSpacing, 20);
    });

    test('should copy with new values', () {
      final bg = PageBackground.grid.copyWith(gridSpacing: 30);
      expect(bg.gridSpacing, 30);
      expect(bg.type, BackgroundType.grid);
    });
  });

  group('BackgroundType', () {
    test('should have all expected values', () {
      expect(BackgroundType.values.length, 5);
    });
  });
}
