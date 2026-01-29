import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('TemplateRegistry', () {
    test('has correct template count', () {
      // 6 basic + 4 productivity + 3 creative + 3 special = 16
      expect(TemplateRegistry.all.length, 16);
    });

    test('has 6 basic templates', () {
      expect(TemplateRegistry.basicTemplates.length, 6);
    });

    test('has 4 productivity templates', () {
      expect(TemplateRegistry.productivityTemplates.length, 4);
    });

    test('has 3 creative templates', () {
      expect(TemplateRegistry.creativeTemplates.length, 3);
    });

    test('has 3 special templates', () {
      expect(TemplateRegistry.specialTemplates.length, 3);
    });

    test('blank getter works', () {
      final template = TemplateRegistry.blank;
      expect(template.id, 'blank');
      expect(template.name, 'Boş');
    });

    test('all basic templates are free', () {
      expect(
        TemplateRegistry.basicTemplates.every((t) => !t.isPremium),
        true,
      );
    });

    test('all productivity templates are premium', () {
      expect(
        TemplateRegistry.productivityTemplates.every((t) => t.isPremium),
        true,
      );
    });

    test('all creative templates are premium', () {
      expect(
        TemplateRegistry.creativeTemplates.every((t) => t.isPremium),
        true,
      );
    });

    test('all special templates are premium', () {
      expect(
        TemplateRegistry.specialTemplates.every((t) => t.isPremium),
        true,
      );
    });

    test('all template IDs are unique', () {
      final ids = TemplateRegistry.all.map((t) => t.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    group('getById', () {
      test('returns template when exists', () {
        final template = TemplateRegistry.getById('blank');
        expect(template, isNotNull);
        expect(template!.id, 'blank');
        expect(template.name, 'Boş');
      });

      test('returns null when not exists', () {
        final template = TemplateRegistry.getById('nonexistent');
        expect(template, isNull);
      });

      test('finds all basic IDs', () {
        final expectedIds = [
          'blank',
          'thin_lined',
          'grid',
          'small_grid',
          'dotted',
          'cornell',
        ];

        for (final id in expectedIds) {
          final template = TemplateRegistry.getById(id);
          expect(template, isNotNull, reason: 'Template $id should exist');
        }
      });
    });

    group('getByCategory', () {
      test('returns correct templates for basic', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.basic);
        expect(templates.length, 6);
        expect(templates.every((t) => t.category == TemplateCategory.basic), true);
      });

      test('returns correct templates for productivity', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.productivity);
        expect(templates.length, 4);
        expect(templates.every((t) => t.category == TemplateCategory.productivity), true);
      });

      test('returns correct templates for creative', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.creative);
        expect(templates.length, 3);
        expect(templates.every((t) => t.category == TemplateCategory.creative), true);
      });

      test('returns correct templates for special', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.special);
        expect(templates.length, 3);
        expect(templates.every((t) => t.category == TemplateCategory.special), true);
      });
    });

    group('getFreeTemplates', () {
      test('returns only free templates', () {
        final free = TemplateRegistry.getFreeTemplates();
        expect(free.every((t) => !t.isPremium), true);
        expect(free.length, 6); // All basic templates
      });
    });

    group('getPremiumTemplates', () {
      test('returns only premium templates', () {
        final premium = TemplateRegistry.getPremiumTemplates();
        expect(premium.every((t) => t.isPremium), true);
        expect(premium.length, 10); // 16 - 6 = 10
      });
    });

    group('getByPattern', () {
      test('returns templates with blank pattern', () {
        final templates = TemplateRegistry.getByPattern(TemplatePattern.blank);
        expect(templates.length, greaterThan(0));
        expect(templates.every((t) => t.pattern == TemplatePattern.blank), true);
      });

      test('returns templates with medium lines pattern', () {
        final templates = TemplateRegistry.getByPattern(TemplatePattern.mediumLines);
        expect(templates.length, greaterThan(0));
        expect(templates.every((t) => t.pattern == TemplatePattern.mediumLines), true);
      });

      test('returns templates with cornell pattern', () {
        final templates = TemplateRegistry.getByPattern(TemplatePattern.cornell);
        expect(templates.length, 1); // Only cornell template
        expect(templates.first.id, 'cornell');
      });
    });

    group('specific templates', () {
      test('blank has correct properties', () {
        final template = TemplateRegistry.getById('blank')!;
        expect(template.name, 'Boş');
        expect(template.nameEn, 'Blank');
        expect(template.category, TemplateCategory.basic);
        expect(template.pattern, TemplatePattern.blank);
        expect(template.isPremium, false);
        expect(template.defaultBackgroundColor, 0xFFFFFFFF);
      });

      test('cornell has correct properties and extraData', () {
        final template = TemplateRegistry.getById('cornell')!;
        expect(template.name, 'Cornell');
        expect(template.category, TemplateCategory.basic);
        expect(template.pattern, TemplatePattern.cornell);
        expect(template.isPremium, false);
        expect(template.extraData, isNotNull);
        expect(template.extraData!['leftMarginRatio'], 0.28);
        expect(template.extraData!['bottomSummaryRatio'], 0.25);
      });

      test('music_staff has correct properties', () {
        final template = TemplateRegistry.getById('music_staff')!;
        expect(template.name, 'Nota Kağıdı');
        expect(template.nameEn, 'Music Staff');
        expect(template.category, TemplateCategory.creative);
        expect(template.pattern, TemplatePattern.music);
        expect(template.isPremium, true);
        expect(template.extraData!['staffLines'], 5);
      });

      test('isometric has correct angle', () {
        final template = TemplateRegistry.getById('isometric')!;
        expect(template.pattern, TemplatePattern.isometric);
        expect(template.extraData!['angle'], 30);
      });
    });

    group('template properties', () {
      test('all templates have unique IDs', () {
        final ids = <String>{};
        for (final template in TemplateRegistry.all) {
          expect(ids.contains(template.id), false, 
              reason: 'Duplicate ID: ${template.id}');
          ids.add(template.id);
        }
      });

      test('all templates have names', () {
        for (final template in TemplateRegistry.all) {
          expect(template.name.isNotEmpty, true);
          expect(template.nameEn.isNotEmpty, true);
        }
      });

      test('all templates have valid categories', () {
        for (final template in TemplateRegistry.all) {
          expect(TemplateCategory.values.contains(template.category), true);
        }
      });

      test('all templates have valid patterns', () {
        for (final template in TemplateRegistry.all) {
          expect(TemplatePattern.values.contains(template.pattern), true);
        }
      });

      test('templates with lines/grids/dots have spacing', () {
        for (final template in TemplateRegistry.all) {
          if (template.pattern.hasLines || 
              template.pattern.hasGrid || 
              template.pattern.hasDots) {
            expect(template.spacingMm, greaterThan(0),
                reason: '${template.id} should have spacing');
          }
        }
      });
    });
  });
}
