import 'package:test/test.dart';
import 'package:drawing_core/drawing_core.dart';

void main() {
  group('TemplateCategory', () {
    test('should have 8 categories', () {
      expect(TemplateCategory.values.length, 8);
    });
    
    test('basic should be free', () {
      expect(TemplateCategory.basic.isFree, true);
      expect(TemplateCategory.basic.isPremium, false);
    });
    
    test('non-basic categories should be premium', () {
      expect(TemplateCategory.productivity.isPremium, true);
      expect(TemplateCategory.creative.isPremium, true);
      expect(TemplateCategory.special.isPremium, true);
    });

    test('new categories should be premium', () {
      expect(TemplateCategory.planning.isPremium, true);
      expect(TemplateCategory.journal.isPremium, true);
      expect(TemplateCategory.education.isPremium, true);
      expect(TemplateCategory.stationery.isPremium, true);
    });

    test('new categories should have displayName', () {
      expect(TemplateCategory.planning.displayName, 'Planlama');
      expect(TemplateCategory.journal.displayName, 'Günlük');
      expect(TemplateCategory.education.displayName, 'Eğitim');
      expect(TemplateCategory.stationery.displayName, 'Kırtasiye');
    });

    test('all categories should have iconName', () {
      for (final cat in TemplateCategory.values) {
        expect(cat.iconName, isNotEmpty);
      }
    });
    
    test('displayName should return Turkish name', () {
      expect(TemplateCategory.basic.displayName, 'Temel');
      expect(TemplateCategory.productivity.displayName, 'Verimlilik');
    });
    
    test('displayNameEn should return English name', () {
      expect(TemplateCategory.basic.displayNameEn, 'Basic');
      expect(TemplateCategory.productivity.displayNameEn, 'Productivity');
    });
  });
  
  group('TemplatePattern', () {
    test('should have 28 patterns', () {
      expect(TemplatePattern.values.length, 28);
    });
    
    test('blank should have zero spacing', () {
      expect(TemplatePattern.blank.defaultSpacingMm, 0);
      expect(TemplatePattern.blank.defaultLineWidth, 0);
    });
    
    test('lined patterns should have correct spacing', () {
      expect(TemplatePattern.thinLines.defaultSpacingMm, 6);
      expect(TemplatePattern.mediumLines.defaultSpacingMm, 8);
      expect(TemplatePattern.thickLines.defaultSpacingMm, 10);
    });
    
    test('grid patterns should have correct spacing', () {
      expect(TemplatePattern.smallGrid.defaultSpacingMm, 5);
      expect(TemplatePattern.mediumGrid.defaultSpacingMm, 7);
      expect(TemplatePattern.largeGrid.defaultSpacingMm, 10);
    });
    
    test('dot patterns should have correct spacing', () {
      expect(TemplatePattern.smallDots.defaultSpacingMm, 5);
      expect(TemplatePattern.mediumDots.defaultSpacingMm, 7);
      expect(TemplatePattern.largeDots.defaultSpacingMm, 10);
    });
    
    test('hasLines should return true for lined patterns', () {
      expect(TemplatePattern.thinLines.hasLines, true);
      expect(TemplatePattern.cornell.hasLines, true);
      expect(TemplatePattern.smallGrid.hasLines, false);
    });
    
    test('hasGrid should return true for grid patterns', () {
      expect(TemplatePattern.smallGrid.hasGrid, true);
      expect(TemplatePattern.isometric.hasGrid, true);
      expect(TemplatePattern.thinLines.hasGrid, false);
    });
    
    test('hasDots should return true for dot patterns', () {
      expect(TemplatePattern.smallDots.hasDots, true);
      expect(TemplatePattern.mediumDots.hasDots, true);
      expect(TemplatePattern.smallGrid.hasDots, false);
    });

    test('new patterns should be structured', () {
      expect(TemplatePattern.dailyPlanner.isStructured, true);
      expect(TemplatePattern.todoList.isStructured, true);
      expect(TemplatePattern.bulletJournal.isStructured, true);
      expect(TemplatePattern.storyboard.isStructured, true);
    });

    test('old patterns should not be structured', () {
      expect(TemplatePattern.blank.isStructured, false);
      expect(TemplatePattern.mediumGrid.isStructured, false);
      expect(TemplatePattern.cornell.isStructured, false);
    });
  });
}
