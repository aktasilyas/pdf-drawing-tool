import 'package:drawing_core/src/models/template.dart';
import 'package:drawing_core/src/models/template_category.dart';
import 'package:drawing_core/src/models/template_pattern.dart';

export 'package:drawing_core/src/services/template_definitions_categories.dart';

// ─── Additions to existing categories ───

/// New basic templates (appended to basicTemplates)
final List<Template> newBasicTemplates = [
  Template(
    id: 'medium_lined',
    name: 'Çizgili',
    nameEn: 'Medium Lined',
    category: TemplateCategory.basic,
    pattern: TemplatePattern.mediumLines,
    isPremium: false,
    spacingMm: 8,
  ),
  Template(
    id: 'wide_ruled',
    name: 'Geniş Çizgili',
    nameEn: 'Wide Ruled',
    category: TemplateCategory.basic,
    pattern: TemplatePattern.thickLines,
    isPremium: false,
    spacingMm: 10,
  ),
];

/// New productivity templates (appended to productivityTemplates)
final List<Template> newProductivityTemplates = [
  Template(
    id: 'meeting_agenda',
    name: 'Toplantı Notları',
    nameEn: 'Meeting Notes',
    category: TemplateCategory.productivity,
    pattern: TemplatePattern.meetingNotes,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'sections': ['attendees', 'agenda', 'notes', 'actionItems'],
    },
  ),
  Template(
    id: 'project_notes',
    name: 'Proje Notları',
    nameEn: 'Project Notes',
    category: TemplateCategory.productivity,
    pattern: TemplatePattern.cornell,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'headerFields': ['projectName', 'date', 'milestone'],
      'variant': 'project',
    },
  ),
];

/// New creative templates (appended to creativeTemplates)
final List<Template> newCreativeTemplates = [
  Template(
    id: 'piano_staff',
    name: 'Piyano Nota',
    nameEn: 'Piano Grand Staff',
    category: TemplateCategory.creative,
    pattern: TemplatePattern.music,
    isPremium: true,
    spacingMm: 7,
    extraData: {
      'staffType': 'grand',
      'systemsPerPage': 5,
    },
  ),
  Template(
    id: 'storyboard_16_9',
    name: 'Storyboard 16:9',
    nameEn: 'Storyboard 16:9',
    category: TemplateCategory.creative,
    pattern: TemplatePattern.storyboard,
    isPremium: true,
    spacingMm: 5,
    extraData: {
      'aspectRatio': '16:9',
      'framesPerPage': 6,
      'showDescription': true,
      'showShotNumber': true,
    },
  ),
  Template(
    id: 'wireframe_mobile',
    name: 'Mobil Wireframe',
    nameEn: 'Mobile Wireframe',
    category: TemplateCategory.creative,
    pattern: TemplatePattern.wireframe,
    isPremium: true,
    spacingMm: 5,
    extraData: {
      'deviceType': 'mobile',
      'framesPerPage': 3,
      'showGrid': true,
    },
  ),
];

/// New special templates (appended to specialTemplates)
final List<Template> newSpecialTemplates = [
  Template(
    id: 'engineer_pad',
    name: 'Mühendis Kağıdı',
    nameEn: 'Engineer Pad',
    category: TemplateCategory.special,
    pattern: TemplatePattern.smallGrid,
    isPremium: true,
    spacingMm: 5,
    extraData: {
      'showMarginLeft': true,
      'marginMm': 25,
    },
  ),
  Template(
    id: 'seyes',
    name: 'Séyès (Fransız)',
    nameEn: 'Séyès (French)',
    category: TemplateCategory.special,
    pattern: TemplatePattern.mediumGrid,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'style': 'seyes',
      'majorLineEvery': 4,
      'showHorizontalMajor': true,
    },
  ),
  Template(
    id: 'dot_grid_5mm',
    name: '5mm Noktalı',
    nameEn: '5mm Dot Grid',
    category: TemplateCategory.special,
    pattern: TemplatePattern.mediumDots,
    isPremium: true,
    spacingMm: 5,
  ),
];
