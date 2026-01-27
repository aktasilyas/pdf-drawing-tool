import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('Template', () {
    group('constructor', () {
      test('creates with required parameters', () {
        final template = Template(
          id: 'test-1',
          name: 'Test Template',
          nameEn: 'Test Template',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        expect(template.id, 'test-1');
        expect(template.name, 'Test Template');
        expect(template.nameEn, 'Test Template');
        expect(template.category, TemplateCategory.basic);
        expect(template.pattern, TemplatePattern.blank);
        expect(template.isPremium, false);
      });

      test('uses pattern defaults for spacing and lineWidth', () {
        final template = Template(
          id: 'test-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.mediumLines,
        );

        expect(template.spacingMm, TemplatePattern.mediumLines.defaultSpacingMm);
        expect(template.lineWidth, TemplatePattern.mediumLines.defaultLineWidth);
      });

      test('allows custom spacing and lineWidth', () {
        final template = Template(
          id: 'test-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.mediumLines,
          spacingMm: 12.0,
          lineWidth: 1.0,
        );

        expect(template.spacingMm, 12.0);
        expect(template.lineWidth, 1.0);
      });

      test('has default colors', () {
        final template = Template(
          id: 'test-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        expect(template.defaultLineColor, 0xFFE0E0E0);
        expect(template.defaultBackgroundColor, 0xFFFFFFFF);
      });

      test('allows custom colors', () {
        final template = Template(
          id: 'test-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
          defaultLineColor: 0xFF000000,
          defaultBackgroundColor: 0xFFCCCCCC,
        );

        expect(template.defaultLineColor, 0xFF000000);
        expect(template.defaultBackgroundColor, 0xFFCCCCCC);
      });

      test('isPremium defaults to false', () {
        final template = Template(
          id: 'test-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.productivity,
          pattern: TemplatePattern.cornell,
        );

        expect(template.isPremium, false);
      });

      test('allows extraData', () {
        final template = Template(
          id: 'test-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
          extraData: {'margin': 20, 'showHeader': true},
        );

        expect(template.extraData, {'margin': 20, 'showHeader': true});
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 'template-1',
          'name': 'Çizgili',
          'nameEn': 'Lined',
          'category': 'basic',
          'pattern': 'mediumLines',
          'isPremium': false,
          'spacingMm': 8.0,
          'lineWidth': 0.5,
          'defaultLineColor': 0xFFE0E0E0,
          'defaultBackgroundColor': 0xFFFFFFFF,
          'extraData': {'custom': 'data'},
        };

        final template = Template.fromJson(json);

        expect(template.id, 'template-1');
        expect(template.name, 'Çizgili');
        expect(template.nameEn, 'Lined');
        expect(template.category, TemplateCategory.basic);
        expect(template.pattern, TemplatePattern.mediumLines);
        expect(template.isPremium, false);
        expect(template.spacingMm, 8.0);
        expect(template.lineWidth, 0.5);
        expect(template.extraData, {'custom': 'data'});
      });

      test('uses name as nameEn fallback', () {
        final json = {
          'id': 'template-1',
          'name': 'Test',
          'category': 'basic',
          'pattern': 'blank',
        };

        final template = Template.fromJson(json);
        expect(template.nameEn, 'Test');
      });

      test('handles unknown category gracefully', () {
        final json = {
          'id': 'template-1',
          'name': 'Test',
          'nameEn': 'Test',
          'category': 'unknown_category',
          'pattern': 'blank',
        };

        final template = Template.fromJson(json);
        expect(template.category, TemplateCategory.basic);
      });

      test('handles unknown pattern gracefully', () {
        final json = {
          'id': 'template-1',
          'name': 'Test',
          'nameEn': 'Test',
          'category': 'basic',
          'pattern': 'unknown_pattern',
        };

        final template = Template.fromJson(json);
        expect(template.pattern, TemplatePattern.blank);
      });

      test('uses pattern defaults when spacing/lineWidth not provided', () {
        final json = {
          'id': 'template-1',
          'name': 'Test',
          'nameEn': 'Test',
          'category': 'basic',
          'pattern': 'smallGrid',
        };

        final template = Template.fromJson(json);
        expect(template.spacingMm, TemplatePattern.smallGrid.defaultSpacingMm);
        expect(template.lineWidth, TemplatePattern.smallGrid.defaultLineWidth);
      });
    });

    group('toJson', () {
      test('converts to JSON correctly', () {
        final template = Template(
          id: 'template-1',
          name: 'Çizgili',
          nameEn: 'Lined',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.mediumLines,
          isPremium: false,
          spacingMm: 8.0,
          lineWidth: 0.5,
          defaultLineColor: 0xFFE0E0E0,
          defaultBackgroundColor: 0xFFFFFFFF,
        );

        final json = template.toJson();

        expect(json['id'], 'template-1');
        expect(json['name'], 'Çizgili');
        expect(json['nameEn'], 'Lined');
        expect(json['category'], 'basic');
        expect(json['pattern'], 'mediumLines');
        expect(json['isPremium'], false);
        expect(json['spacingMm'], 8.0);
        expect(json['lineWidth'], 0.5);
      });

      test('excludes extraData when null', () {
        final template = Template(
          id: 'template-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        final json = template.toJson();
        expect(json.containsKey('extraData'), false);
      });

      test('includes extraData when present', () {
        final template = Template(
          id: 'template-1',
          name: 'Test',
          nameEn: 'Test',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
          extraData: {'key': 'value'},
        );

        final json = template.toJson();
        expect(json['extraData'], {'key': 'value'});
      });
    });

    group('JSON roundtrip', () {
      test('toJson and fromJson are inverse operations', () {
        final original = Template(
          id: 'roundtrip-test',
          name: 'Round Trip',
          nameEn: 'Round Trip EN',
          category: TemplateCategory.productivity,
          pattern: TemplatePattern.cornell,
          isPremium: true,
          spacingMm: 10.0,
          lineWidth: 0.8,
          defaultLineColor: 0xFF333333,
          defaultBackgroundColor: 0xFFFFFFF0,
          extraData: {'margin': 50},
        );

        final json = original.toJson();
        final restored = Template.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.nameEn, original.nameEn);
        expect(restored.category, original.category);
        expect(restored.pattern, original.pattern);
        expect(restored.isPremium, original.isPremium);
        expect(restored.spacingMm, original.spacingMm);
        expect(restored.lineWidth, original.lineWidth);
        expect(restored.defaultLineColor, original.defaultLineColor);
        expect(restored.defaultBackgroundColor, original.defaultBackgroundColor);
        expect(restored.extraData, original.extraData);
      });
    });

    group('copyWith', () {
      test('copies with single property changed', () {
        final original = Template(
          id: 'test-1',
          name: 'Original',
          nameEn: 'Original EN',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        final copy = original.copyWith(name: 'Modified');

        expect(copy.name, 'Modified');
        expect(copy.id, original.id);
        expect(copy.nameEn, original.nameEn);
        expect(copy.category, original.category);
        expect(copy.pattern, original.pattern);
      });

      test('copies with multiple properties changed', () {
        final original = Template(
          id: 'test-1',
          name: 'Original',
          nameEn: 'Original EN',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        final copy = original.copyWith(
          name: 'Modified',
          category: TemplateCategory.productivity,
          isPremium: true,
        );

        expect(copy.name, 'Modified');
        expect(copy.category, TemplateCategory.productivity);
        expect(copy.isPremium, true);
        expect(copy.id, original.id);
      });

      test('copies with all properties changed', () {
        final original = Template(
          id: 'test-1',
          name: 'Original',
          nameEn: 'Original EN',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        final copy = original.copyWith(
          id: 'test-2',
          name: 'New',
          nameEn: 'New EN',
          category: TemplateCategory.creative,
          pattern: TemplatePattern.music,
          isPremium: true,
          spacingMm: 15.0,
          lineWidth: 1.5,
          defaultLineColor: 0xFF000000,
          defaultBackgroundColor: 0xFFEEEEEE,
          extraData: {'staff': 5},
        );

        expect(copy.id, 'test-2');
        expect(copy.name, 'New');
        expect(copy.nameEn, 'New EN');
        expect(copy.category, TemplateCategory.creative);
        expect(copy.pattern, TemplatePattern.music);
        expect(copy.isPremium, true);
        expect(copy.spacingMm, 15.0);
        expect(copy.lineWidth, 1.5);
        expect(copy.defaultLineColor, 0xFF000000);
        expect(copy.defaultBackgroundColor, 0xFFEEEEEE);
        expect(copy.extraData, {'staff': 5});
      });
    });

    group('equality', () {
      test('same id equals', () {
        final template1 = Template(
          id: 'same-id',
          name: 'Template 1',
          nameEn: 'Template 1',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        final template2 = Template(
          id: 'same-id',
          name: 'Different Name',
          nameEn: 'Different Name',
          category: TemplateCategory.productivity,
          pattern: TemplatePattern.cornell,
        );

        expect(template1, equals(template2));
        expect(template1.hashCode, equals(template2.hashCode));
      });

      test('different id not equals', () {
        final template1 = Template(
          id: 'id-1',
          name: 'Same Name',
          nameEn: 'Same Name',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        final template2 = Template(
          id: 'id-2',
          name: 'Same Name',
          nameEn: 'Same Name',
          category: TemplateCategory.basic,
          pattern: TemplatePattern.blank,
        );

        expect(template1, isNot(equals(template2)));
      });
    });
  });
}
