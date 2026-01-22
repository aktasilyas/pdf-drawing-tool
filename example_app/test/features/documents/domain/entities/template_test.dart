import 'package:flutter_test/flutter_test.dart';
import 'package:example_app/features/documents/documents.dart';

void main() {
  group('Template', () {
    test('should have 7 predefined templates', () {
      expect(Template.all.length, 7);
    });

    test('should have 6 free templates', () {
      expect(Template.freeTemplates.length, 6);
    });

    test('should have 1 premium template', () {
      expect(Template.premiumTemplates.length, 1);
    });

    test('should correctly identify blank template', () {
      final blank = Template.all.first;
      expect(blank.id, 'blank');
      expect(blank.name, 'Boş');
      expect(blank.type, TemplateType.blank);
      expect(blank.isPremium, false);
    });

    test('should correctly identify cornell as premium', () {
      final cornell = Template.all.last;
      expect(cornell.id, 'cornell');
      expect(cornell.name, 'Cornell');
      expect(cornell.isPremium, true);
    });

    test('should get template by id', () {
      final template = Template.getById('blank');
      expect(template, isNotNull);
      expect(template?.id, 'blank');
    });

    test('should return null for non-existent id', () {
      final template = Template.getById('non-existent');
      expect(template, isNull);
    });

    test('all free templates should not be premium', () {
      for (final template in Template.freeTemplates) {
        expect(template.isPremium, false);
      }
    });

    test('all premium templates should be premium', () {
      for (final template in Template.premiumTemplates) {
        expect(template.isPremium, true);
      }
    });
  });
}
