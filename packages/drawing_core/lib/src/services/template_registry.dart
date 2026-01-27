import 'package:drawing_core/src/models/template.dart';
import 'package:drawing_core/src/models/template_category.dart';
import 'package:drawing_core/src/models/template_pattern.dart';

/// Template registry with all 44+ predefined templates.
class TemplateRegistry {
  TemplateRegistry._();

  /// All available templates
  static final List<Template> all = [
    // === BASIC (Free) - 12 Templates ===
    ...basicTemplates,
    
    // === PRODUCTIVITY (Premium) - 8 Templates ===
    ...productivityTemplates,
    
    // === CREATIVE (Premium) - 6 Templates ===
    ...creativeTemplates,
    
    // === EDUCATION (Premium) - 6 Templates ===
    ...educationTemplates,
    
    // === PLANNING (Premium) - 6 Templates ===
    ...planningTemplates,
    
    // === SPECIAL (Premium) - 6 Templates ===
    ...specialTemplates,
  ];

  /// Basic templates (Free)
  static final List<Template> basicTemplates = [
    Template(
      id: 'blank_white',
      name: 'Boş (Beyaz)',
      nameEn: 'Blank (White)',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.blank,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFFFF,
    ),
    Template(
      id: 'blank_cream',
      name: 'Boş (Krem)',
      nameEn: 'Blank (Cream)',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.blank,
      isPremium: false,
      defaultBackgroundColor: 0xFFFFFDE7,
    ),
    Template(
      id: 'blank_gray',
      name: 'Boş (Gri)',
      nameEn: 'Blank (Gray)',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.blank,
      isPremium: false,
      defaultBackgroundColor: 0xFFF5F5F5,
    ),
    Template(
      id: 'thin_lined',
      name: 'İnce Çizgili',
      nameEn: 'Thin Lined',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.thinLines,
      isPremium: false,
      spacingMm: 6,
    ),
    Template(
      id: 'medium_lined',
      name: 'Orta Çizgili',
      nameEn: 'Medium Lined',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.mediumLines,
      isPremium: false,
      spacingMm: 8,
    ),
    Template(
      id: 'thick_lined',
      name: 'Kalın Çizgili',
      nameEn: 'Thick Lined',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.thickLines,
      isPremium: false,
      spacingMm: 10,
    ),
    Template(
      id: 'small_grid',
      name: 'Küçük Kareli',
      nameEn: 'Small Grid',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.smallGrid,
      isPremium: false,
      spacingMm: 5,
    ),
    Template(
      id: 'medium_grid',
      name: 'Orta Kareli',
      nameEn: 'Medium Grid',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.mediumGrid,
      isPremium: false,
      spacingMm: 7,
    ),
    Template(
      id: 'large_grid',
      name: 'Büyük Kareli',
      nameEn: 'Large Grid',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.largeGrid,
      isPremium: false,
      spacingMm: 10,
    ),
    Template(
      id: 'small_dots',
      name: 'Küçük Noktalı',
      nameEn: 'Small Dots',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.smallDots,
      isPremium: false,
      spacingMm: 5,
    ),
    Template(
      id: 'medium_dots',
      name: 'Orta Noktalı',
      nameEn: 'Medium Dots',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.mediumDots,
      isPremium: false,
      spacingMm: 7,
    ),
    Template(
      id: 'large_dots',
      name: 'Büyük Noktalı',
      nameEn: 'Large Dots',
      category: TemplateCategory.basic,
      pattern: TemplatePattern.largeDots,
      isPremium: false,
      spacingMm: 10,
    ),
  ];

  /// Productivity templates (Premium)
  static final List<Template> productivityTemplates = [
    Template(
      id: 'cornell',
      name: 'Cornell Notes',
      nameEn: 'Cornell Notes',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.cornell,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'leftMarginRatio': 0.28,
        'bottomSummaryRatio': 0.25,
      },
    ),
    Template(
      id: 'todo_list',
      name: 'Yapılacaklar',
      nameEn: 'To-Do List',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 10,
      extraData: {
        'hasCheckboxes': true,
        'checkboxSize': 16,
      },
    ),
    Template(
      id: 'meeting_notes',
      name: 'Toplantı Notu',
      nameEn: 'Meeting Notes',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      extraData: {
        'sections': ['Tarih', 'Katılımcılar', 'Notlar', 'Aksiyonlar'],
      },
    ),
    Template(
      id: 'daily_planner',
      name: 'Günlük Plan',
      nameEn: 'Daily Planner',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      extraData: {
        'timeSlots': true,
        'startHour': 6,
        'endHour': 22,
        'slotDuration': 30,
      },
    ),
    Template(
      id: 'weekly_planner',
      name: 'Haftalık Plan',
      nameEn: 'Weekly Planner',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.smallGrid,
      isPremium: true,
      extraData: {
        'days': 7,
        'columns': ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
      },
    ),
    Template(
      id: 'project_tracker',
      name: 'Proje Takip',
      nameEn: 'Project Tracker',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      extraData: {
        'milestones': true,
        'timelineFormat': 'horizontal',
      },
    ),
    Template(
      id: 'habit_tracker',
      name: 'Alışkanlık Takip',
      nameEn: 'Habit Tracker',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.smallGrid,
      isPremium: true,
      extraData: {
        'days': 30,
        'gridLayout': true,
      },
    ),
    Template(
      id: 'goal_setting',
      name: 'Hedef Belirleme',
      nameEn: 'Goal Setting',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      extraData: {
        'smartFormat': true,
        'sections': ['Specific', 'Measurable', 'Achievable', 'Relevant', 'Time-bound'],
      },
    ),
  ];

  /// Creative templates (Premium)
  static final List<Template> creativeTemplates = [
    Template(
      id: 'storyboard',
      name: 'Storyboard',
      nameEn: 'Storyboard',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.blank,
      isPremium: true,
      extraData: {
        'frames': 6,
        'layout': '2x3',
        'aspectRatio': 16 / 9,
      },
    ),
    Template(
      id: 'music_staff',
      name: 'Nota Kağıdı',
      nameEn: 'Music Staff',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.music,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'staffLines': 5,
        'staffCount': 8,
      },
    ),
    Template(
      id: 'comic_panel',
      name: 'Çizgi Roman',
      nameEn: 'Comic Panel',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.blank,
      isPremium: true,
      extraData: {
        'panelLayout': 'standard',
        'gutterSize': 10,
      },
    ),
    Template(
      id: 'sketch_guide',
      name: 'Eskiz Rehber',
      nameEn: 'Sketch Guide',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.blank,
      isPremium: true,
      extraData: {
        'perspectiveLines': true,
        'vanishingPoints': 2,
      },
    ),
    Template(
      id: 'calligraphy',
      name: 'Kaligrafi',
      nameEn: 'Calligraphy',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.calligraphy,
      isPremium: true,
      spacingMm: 12,
      extraData: {
        'angleGuides': true,
        'angle': 55,
      },
    ),
    Template(
      id: 'lettering',
      name: 'Lettering',
      nameEn: 'Lettering',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.handwriting,
      isPremium: true,
      spacingMm: 10,
      extraData: {
        'baseline': true,
        'xHeight': true,
        'capHeight': true,
      },
    ),
  ];

  /// Education templates (Premium)
  static final List<Template> educationTemplates = [
    Template(
      id: 'math_grid',
      name: 'Matematik',
      nameEn: 'Math Grid',
      category: TemplateCategory.education,
      pattern: TemplatePattern.smallGrid,
      isPremium: true,
      spacingMm: 5,
      extraData: {
        'coordinateAxes': true,
        'origin': 'center',
      },
    ),
    Template(
      id: 'graph_paper',
      name: 'Grafik Kağıdı',
      nameEn: 'Graph Paper',
      category: TemplateCategory.education,
      pattern: TemplatePattern.mediumGrid,
      isPremium: true,
      spacingMm: 7,
      extraData: {
        'axes': true,
        'boldEvery': 5,
      },
    ),
    Template(
      id: 'handwriting',
      name: 'El Yazısı',
      nameEn: 'Handwriting',
      category: TemplateCategory.education,
      pattern: TemplatePattern.handwriting,
      isPremium: true,
      spacingMm: 10,
      extraData: {
        'middleLine': true,
        'dashedGuide': true,
      },
    ),
    Template(
      id: 'chinese_grid',
      name: 'Çince/Japonca',
      nameEn: 'Chinese/Japanese Grid',
      category: TemplateCategory.education,
      pattern: TemplatePattern.largeGrid,
      isPremium: true,
      spacingMm: 15,
      extraData: {
        'characterGuides': true,
        'crosshair': true,
      },
    ),
    Template(
      id: 'vocabulary',
      name: 'Kelime Defteri',
      nameEn: 'Vocabulary',
      category: TemplateCategory.education,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'columns': 2,
        'columnRatio': 0.5,
        'dividerLine': true,
      },
    ),
    Template(
      id: 'flashcard',
      name: 'Flash Kart',
      nameEn: 'Flashcard',
      category: TemplateCategory.education,
      pattern: TemplatePattern.blank,
      isPremium: true,
      extraData: {
        'frontBack': true,
        'dividerLine': 'horizontal',
      },
    ),
  ];

  /// Planning templates (Premium)
  static final List<Template> planningTemplates = [
    Template(
      id: 'monthly_cal',
      name: 'Aylık Takvim',
      nameEn: 'Monthly Calendar',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.largeGrid,
      isPremium: true,
      extraData: {
        'layout': '5x7',
        'weekStartsOn': 'monday',
      },
    ),
    Template(
      id: 'yearly_overview',
      name: 'Yıllık Bakış',
      nameEn: 'Yearly Overview',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.smallGrid,
      isPremium: true,
      extraData: {
        'months': 12,
        'layout': '3x4',
      },
    ),
    Template(
      id: 'budget_tracker',
      name: 'Bütçe Takip',
      nameEn: 'Budget Tracker',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      extraData: {
        'columns': ['Tarih', 'Gelir', 'Gider', 'Kalan'],
        'hasTotal': true,
      },
    ),
    Template(
      id: 'meal_planner',
      name: 'Yemek Planı',
      nameEn: 'Meal Planner',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.smallGrid,
      isPremium: true,
      extraData: {
        'days': 7,
        'meals': ['Kahvaltı', 'Öğle', 'Akşam'],
      },
    ),
    Template(
      id: 'fitness_log',
      name: 'Fitness Log',
      nameEn: 'Fitness Log',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      extraData: {
        'columns': ['Egzersiz', 'Set', 'Tekrar', 'Ağırlık'],
      },
    ),
    Template(
      id: 'travel_itinerary',
      name: 'Seyahat Planı',
      nameEn: 'Travel Itinerary',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      extraData: {
        'timeline': true,
        'sections': ['Tarih', 'Yer', 'Aktivite', 'Notlar'],
      },
    ),
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
      spacingMm: 12,
      extraData: {
        'hexSize': 12,
        'orientation': 'pointy',
      },
    ),
    Template(
      id: 'seyes',
      name: 'Séyès (Fransız)',
      nameEn: 'Séyès (French)',
      category: TemplateCategory.special,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'verticalLines': true,
        'verticalSpacing': 8,
        'boldEvery': 4,
      },
    ),
    Template(
      id: 'engineer_pad',
      name: 'Mühendis',
      nameEn: 'Engineer Pad',
      category: TemplateCategory.special,
      pattern: TemplatePattern.smallGrid,
      isPremium: true,
      spacingMm: 5,
      extraData: {
        'leftMargin': 30,
        'marginLine': true,
        'boldEvery': 5,
      },
    ),
    Template(
      id: 'legal_pad',
      name: 'Legal Pad',
      nameEn: 'Legal Pad',
      category: TemplateCategory.special,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 8,
      defaultBackgroundColor: 0xFFFFFDE7, // Yellow
      extraData: {
        'leftMargin': 32,
        'marginLineColor': 0xFFFF0000, // Red
      },
    ),
    Template(
      id: 'manuscript',
      name: 'El Yazması',
      nameEn: 'Manuscript',
      category: TemplateCategory.special,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 9,
      defaultBackgroundColor: 0xFFFFFAF0, // Vintage cream
      extraData: {
        'vintage': true,
        'decorativeBorder': true,
      },
    ),
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
