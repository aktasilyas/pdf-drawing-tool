import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('TemplateRegistry', () {
    test('has 44 templates total', () {
      expect(TemplateRegistry.all.length, 44);
    });

    test('has 12 basic templates', () {
      expect(TemplateRegistry.basicTemplates.length, 12);
    });

    test('has 8 productivity templates', () {
      expect(TemplateRegistry.productivityTemplates.length, 8);
    });

    test('has 6 creative templates', () {
      expect(TemplateRegistry.creativeTemplates.length, 6);
    });

    test('has 6 education templates', () {
      expect(TemplateRegistry.educationTemplates.length, 6);
    });

    test('has 6 planning templates', () {
      expect(TemplateRegistry.planningTemplates.length, 6);
    });

    test('has 6 special templates', () {
      expect(TemplateRegistry.specialTemplates.length, 6);
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

    test('all education templates are premium', () {
      expect(
        TemplateRegistry.educationTemplates.every((t) => t.isPremium),
        true,
      );
    });

    test('all planning templates are premium', () {
      expect(
        TemplateRegistry.planningTemplates.every((t) => t.isPremium),
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
        final template = TemplateRegistry.getById('blank_white');
        expect(template, isNotNull);
        expect(template!.id, 'blank_white');
        expect(template.name, 'Boş (Beyaz)');
      });

      test('returns null when not exists', () {
        final template = TemplateRegistry.getById('nonexistent');
        expect(template, isNull);
      });

      test('finds all expected IDs', () {
        final expectedIds = [
          'blank_white', 'blank_cream', 'blank_gray',
          'thin_lined', 'medium_lined', 'thick_lined',
          'small_grid', 'medium_grid', 'large_grid',
          'small_dots', 'medium_dots', 'large_dots',
          'cornell', 'todo_list', 'meeting_notes',
          'daily_planner', 'weekly_planner', 'project_tracker',
          'habit_tracker', 'goal_setting',
          'storyboard', 'music_staff', 'comic_panel',
          'sketch_guide', 'calligraphy', 'lettering',
          'math_grid', 'graph_paper', 'handwriting',
          'chinese_grid', 'vocabulary', 'flashcard',
          'monthly_cal', 'yearly_overview', 'budget_tracker',
          'meal_planner', 'fitness_log', 'travel_itinerary',
          'isometric', 'hexagonal', 'seyes',
          'engineer_pad', 'legal_pad', 'manuscript',
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
        expect(templates.length, 12);
        expect(templates.every((t) => t.category == TemplateCategory.basic), true);
      });

      test('returns correct templates for productivity', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.productivity);
        expect(templates.length, 8);
        expect(templates.every((t) => t.category == TemplateCategory.productivity), true);
      });

      test('returns correct templates for creative', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.creative);
        expect(templates.length, 6);
        expect(templates.every((t) => t.category == TemplateCategory.creative), true);
      });

      test('returns correct templates for education', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.education);
        expect(templates.length, 6);
        expect(templates.every((t) => t.category == TemplateCategory.education), true);
      });

      test('returns correct templates for planning', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.planning);
        expect(templates.length, 6);
        expect(templates.every((t) => t.category == TemplateCategory.planning), true);
      });

      test('returns correct templates for special', () {
        final templates = TemplateRegistry.getByCategory(TemplateCategory.special);
        expect(templates.length, 6);
        expect(templates.every((t) => t.category == TemplateCategory.special), true);
      });
    });

    group('getFreeTemplates', () {
      test('returns only free templates', () {
        final free = TemplateRegistry.getFreeTemplates();
        expect(free.every((t) => !t.isPremium), true);
        expect(free.length, 12); // All basic templates
      });
    });

    group('getPremiumTemplates', () {
      test('returns only premium templates', () {
        final premium = TemplateRegistry.getPremiumTemplates();
        expect(premium.every((t) => t.isPremium), true);
        expect(premium.length, 32); // 44 - 12 = 32
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
      test('blank_white has correct properties', () {
        final template = TemplateRegistry.getById('blank_white')!;
        expect(template.name, 'Boş (Beyaz)');
        expect(template.nameEn, 'Blank (White)');
        expect(template.category, TemplateCategory.basic);
        expect(template.pattern, TemplatePattern.blank);
        expect(template.isPremium, false);
        expect(template.defaultBackgroundColor, 0xFFFFFFFF);
      });

      test('cornell has correct properties and extraData', () {
        final template = TemplateRegistry.getById('cornell')!;
        expect(template.name, 'Cornell Notes');
        expect(template.category, TemplateCategory.productivity);
        expect(template.pattern, TemplatePattern.cornell);
        expect(template.isPremium, true);
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

      test('legal_pad has yellow background', () {
        final template = TemplateRegistry.getById('legal_pad')!;
        expect(template.defaultBackgroundColor, 0xFFFFFDE7);
        expect(template.extraData!['marginLineColor'], 0xFFFF0000);
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
