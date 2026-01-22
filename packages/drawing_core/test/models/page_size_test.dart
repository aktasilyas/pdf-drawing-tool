import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('PageSize', () {
    test('should create with custom dimensions', () {
      final size = PageSize(width: 800, height: 600);
      expect(size.width, 800);
      expect(size.height, 600);
      expect(size.isLandscape, true);
    });

    test('should have correct A4 dimensions', () {
      expect(PageSize.a4Portrait.width, 595);
      expect(PageSize.a4Portrait.height, 842);
      expect(PageSize.a4Portrait.preset, PagePreset.a4Portrait);
    });

    test('should calculate aspect ratio', () {
      final size = PageSize(width: 800, height: 400);
      expect(size.aspectRatio, 2.0);
    });

    test('should serialize to JSON', () {
      final json = PageSize.a4Portrait.toJson();
      expect(json['width'], 595);
      expect(json['height'], 842);
      expect(json['preset'], 'a4Portrait');
    });

    test('should deserialize from JSON', () {
      final json = {'width': 595, 'height': 842, 'preset': 'a4Portrait'};
      final size = PageSize.fromJson(json);
      expect(size, PageSize.a4Portrait);
    });

    test('should handle equality', () {
      final size1 = PageSize(width: 100, height: 200);
      final size2 = PageSize(width: 100, height: 200);
      expect(size1, size2);
    });
  });

  group('PagePreset', () {
    test('should have all expected values', () {
      expect(PagePreset.values.length, 5);
      expect(PagePreset.values, contains(PagePreset.a4Portrait));
      expect(PagePreset.values, contains(PagePreset.custom));
    });
  });
}
