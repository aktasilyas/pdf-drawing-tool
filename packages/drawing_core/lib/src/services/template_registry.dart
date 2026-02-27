import 'package:drawing_core/src/models/template.dart';
import 'package:drawing_core/src/models/template_category.dart';
import 'package:drawing_core/src/models/template_pattern.dart';
import 'package:drawing_core/src/services/template_definitions_new.dart' as ext;

/// Template registry — 32 templates (9 free + 23 premium) across 8 categories.
class TemplateRegistry {
  TemplateRegistry._();

  static final List<Template> all = [
    ...basicTemplates,
    ...productivityTemplates,
    ...creativeTemplates,
    ...specialTemplates,
    ...planningTemplates,
    ...journalTemplates,
    ...educationTemplates,
    ...stationeryTemplates,
  ];

  static final List<Template> planningTemplates = ext.planningTemplates;
  static final List<Template> journalTemplates = ext.journalTemplates;
  static final List<Template> educationTemplates = ext.educationTemplates;
  static final List<Template> stationeryTemplates = ext.stationeryTemplates;

  static Template get blank => getById('blank')!;

  /// Basic templates (Free)
  static final List<Template> basicTemplates = [
    Template(
      id: 'blank',
      name: 'Boş',
      nameEn: 'Blank',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.blank,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
    ),
    Template(
      id: 'thin_lined',
      name: 'İnce Çizgili',
      nameEn: 'Thin Lined',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.thinLines,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 6,
    ),
    Template(
      id: 'grid',
      name: 'Kareli',
      nameEn: 'Grid',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.mediumGrid,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 7,
    ),
    Template(
      id: 'small_grid',
      name: 'Küçük Kareli',
      nameEn: 'Small Grid',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.smallGrid,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 5,
    ),
    Template(
      id: 'dotted',
      name: 'Noktalı',
      nameEn: 'Dotted',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.largeDots,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 8,
    ),
    Template(
      id: 'cornell',
      name: 'Cornell',
      nameEn: 'Cornell Notes',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.cornell,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 8,
      extraData: {
        'leftMarginRatio': 0.28,
        'bottomSummaryRatio': 0.25,
      },
    ),
    ...ext.newBasicTemplates,
  ];

  static final List<Template> productivityTemplates = [
    ...ext.newProductivityTemplates,
  ];

  /// Creative templates (Premium)
  static final List<Template> creativeTemplates = [
    Template(
      id: 'music_staff',
      name: 'Nota Kağıdı',
      nameEn: 'Music Staff',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.music,
      isPremium: true,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFF000000,
      spacingMm: 12,
      lineWidth: 1.2,
      extraData: {
        'staffLines': 5,
        'staffCount': 8,
      },
    ),
    Template(
      id: 'handwriting',
      name: 'El Yazısı',
      nameEn: 'Handwriting',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.handwriting,
      isPremium: true,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 10,
      extraData: {
        'baseline': true,
        'xHeight': true,
        'capHeight': true,
      },
    ),
    ...ext.newCreativeTemplates,
  ];

  /// Special templates (Premium)
  static final List<Template> specialTemplates = [
    Template(
      id: 'isometric',
      name: 'İzometrik',
      nameEn: 'Isometric',
      category: TemplateCategory.special,
      pattern: TemplatePattern.isometric,
      isPremium: true,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 10,
      extraData: {
        'angle': 30,
        'type': 'isometric',
      },
    ),
    Template(
      id: 'hexagonal',
      name: 'Altıgen',
      nameEn: 'Hexagonal',
      category: TemplateCategory.special,
      pattern: TemplatePattern.hexagonal,
      isPremium: true,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 12,
      extraData: {
        'hexSize': 12,
        'orientation': 'pointy',
      },
    ),
    Template(
      id: 'calligraphy',
      name: 'Kaligrafi',
      nameEn: 'Calligraphy',
      category: TemplateCategory.special,
      pattern: TemplatePattern.calligraphy,
      isPremium: true,
      defaultBackgroundColor: 0xFFFFFFFF,
      defaultLineColor: 0xFFE0E0E0,
      spacingMm: 12,
      extraData: {
        'angleGuides': true,
        'angle': 55,
      },
    ),
    ...ext.newSpecialTemplates,
  ];

  /// Get template by ID
  static Template? getById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get templates by category
  static List<Template> getByCategory(TemplateCategory category) {
    return all.where((t) => t.category == category).toList();
  }

  /// Get free templates only
  static List<Template> getFreeTemplates() {
    return all.where((t) => !t.isPremium).toList();
  }

  /// Get premium templates only
  static List<Template> getPremiumTemplates() {
    return all.where((t) => t.isPremium).toList();
  }

  /// Get templates by pattern
  static List<Template> getByPattern(TemplatePattern pattern) {
    return all.where((t) => t.pattern == pattern).toList();
  }
}
