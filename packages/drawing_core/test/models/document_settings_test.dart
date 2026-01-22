import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('DocumentSettings', () {
    test('should create with default values', () {
      final settings = DocumentSettings.defaults();
      expect(settings.defaultPageSize, PageSize.a4Portrait);
      expect(settings.defaultBackground, PageBackground.blank);
    });

    test('should create with custom values', () {
      final settings = DocumentSettings(
        defaultPageSize: PageSize.letterLandscape,
        defaultBackground: PageBackground.grid,
      );
      expect(settings.defaultPageSize, PageSize.letterLandscape);
      expect(settings.defaultBackground.type, BackgroundType.grid);
    });

    test('should serialize to JSON', () {
      final settings = DocumentSettings.defaults();
      final json = settings.toJson();
      expect(json['defaultPageSize'], isNotNull);
      expect(json['defaultBackground'], isNotNull);
    });

    test('should deserialize from JSON', () {
      final settings = DocumentSettings.defaults();
      final json = settings.toJson();
      final restored = DocumentSettings.fromJson(json);
      expect(restored.defaultPageSize, settings.defaultPageSize);
      expect(restored.defaultBackground.type, settings.defaultBackground.type);
    });

    test('should copy with new values', () {
      final settings = DocumentSettings.defaults();
      final updated = settings.copyWith(
        defaultPageSize: PageSize.letterPortrait,
      );
      expect(updated.defaultPageSize, PageSize.letterPortrait);
      expect(updated.defaultBackground, settings.defaultBackground);
    });
  });
}
