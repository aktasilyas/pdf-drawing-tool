import 'dart:convert';
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

  group('PageBackground templateExtraData', () {
    Template tpl(String id) => TemplateRegistry.getById(id)!;

    test('fromTemplate copies template fields and extraData', () {
      final t = tpl('engineer_pad');
      final bg = PageBackground.fromTemplate(t);
      expect(bg.type, BackgroundType.template);
      expect(bg.templatePattern, t.pattern);
      expect(bg.templateSpacingMm, t.spacingMm);
      expect(bg.templateLineWidth, t.lineWidth);
      expect(bg.color, t.defaultBackgroundColor);
      expect(bg.lineColor, t.defaultLineColor);
      expect(bg.templateExtraData, {'showMarginLeft': true, 'marginMm': 25});
    });

    test('fromTemplate honours color overrides', () {
      final bg = PageBackground.fromTemplate(
        tpl('engineer_pad'),
        color: 0xFF111111,
        lineColor: 0xFF222222,
      );
      expect(bg.color, 0xFF111111);
      expect(bg.lineColor, 0xFF222222);
    });

    test('fromTemplate leaves extraData null when template has none', () {
      final bg = PageBackground.fromTemplate(
          TemplateRegistry.all.firstWhere((t) => t.extraData == null));
      expect(bg.templateExtraData, isNull);
    });

    test('extraData map is unmodifiable', () {
      final bg = PageBackground.fromTemplate(tpl('engineer_pad'));
      expect(() => bg.templateExtraData!['x'] = 1, throwsUnsupportedError);
      final fromJson = PageBackground.fromJson({
        'type': 'template',
        'templateExtraData': {'a': 1},
      });
      expect(
          () => fromJson.templateExtraData!['x'] = 1, throwsUnsupportedError);
    });

    for (final id in [
      'engineer_pad',
      'calligraphy_copperplate',
      'vocabulary'
    ]) {
      test('JSON round trip keeps extraData for $id', () {
        final bg = PageBackground.fromTemplate(tpl(id));
        final decoded =
            jsonDecode(jsonEncode(bg.toJson())) as Map<String, dynamic>;
        final back = PageBackground.fromJson(decoded);
        expect(back.templateExtraData, bg.templateExtraData);
        expect(back, bg);
        expect(back.hashCode, bg.hashCode);
      });
    }

    test('legacy JSON without the key loads with null extraData', () {
      final bg = PageBackground.fromJson({
        'type': 'template',
        'color': 0xFFFFFFFF,
        'templatePattern': 'smallGrid',
      });
      expect(bg.templateExtraData, isNull);
    });

    test('empty map is not serialized', () {
      final bg = PageBackground.blank.copyWith(templateExtraData: const {});
      expect(bg.toJson().containsKey('templateExtraData'), isFalse);
    });

    test('equality is deep over extraData', () {
      final a = PageBackground.fromTemplate(tpl('vocabulary'));
      final b = PageBackground.fromJson(
          jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);
      expect(identical(a.templateExtraData, b.templateExtraData), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(templateExtraData: {'columns': []}), isFalse);
      expect(a == a.copyWith(color: 0xFF000000), isFalse);
      expect(PageBackground.blank,
          const PageBackground(type: BackgroundType.blank));
    });

    test('copyWith keeps and replaces extraData', () {
      final a = PageBackground.fromTemplate(tpl('engineer_pad'));
      expect(
          a.copyWith(color: 0xFF000000).templateExtraData, a.templateExtraData);
      expect(
          a.copyWith(templateExtraData: {'k': 1}).templateExtraData, {'k': 1});
    });
  });

  group('BackgroundType', () {
    test('should have all expected values', () {
      expect(BackgroundType.values.length, 7);
    });
  });
}
