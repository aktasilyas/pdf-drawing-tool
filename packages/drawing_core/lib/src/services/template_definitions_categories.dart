import 'package:drawing_core/src/models/template.dart';
import 'package:drawing_core/src/models/template_category.dart';
import 'package:drawing_core/src/models/template_pattern.dart';

// ─── New category lists (re-exported by template_definitions_new.dart) ───

/// Planning templates (Premium)
final List<Template> planningTemplates = [
  Template(
    id: 'daily_schedule',
    name: 'Günlük Plan',
    nameEn: 'Daily Planner',
    category: TemplateCategory.planning,
    pattern: TemplatePattern.dailyPlanner,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'startHour': 6,
      'endHour': 22,
      'showGoals': true,
      'showNotes': true,
    },
  ),
  Template(
    id: 'weekly_schedule',
    name: 'Haftalık Plan',
    nameEn: 'Weekly Planner',
    category: TemplateCategory.planning,
    pattern: TemplatePattern.weeklyPlanner,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'startDay': 'monday',
      'showPriorities': true,
    },
  ),
  Template(
    id: 'monthly_planner',
    name: 'Aylık Plan',
    nameEn: 'Monthly Planner',
    category: TemplateCategory.planning,
    pattern: TemplatePattern.monthlyPlanner,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'showGoals': true,
      'gridRows': 6,
      'gridCols': 7,
    },
  ),
];

/// Journal templates (Premium)
final List<Template> journalTemplates = [
  Template(
    id: 'bullet_journal',
    name: 'Bullet Journal',
    nameEn: 'Bullet Journal',
    category: TemplateCategory.journal,
    pattern: TemplatePattern.bulletJournal,
    isPremium: true,
    spacingMm: 7,
    extraData: {
      'showIndex': true,
      'showSignifiers': true,
      'dotGrid': true,
    },
  ),
  Template(
    id: 'gratitude',
    name: 'Teşekkür Günlüğü',
    nameEn: 'Gratitude Journal',
    category: TemplateCategory.journal,
    pattern: TemplatePattern.gratitudeJournal,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'promptCount': 3,
      'showMoodScale': true,
      'showDailyEvent': true,
    },
  ),
  Template(
    id: 'reading_log',
    name: 'Okuma Günlüğü',
    nameEn: 'Reading Log',
    category: TemplateCategory.journal,
    pattern: TemplatePattern.readingLog,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'columns': ['title', 'author', 'pages', 'rating', 'notes'],
    },
  ),
];

/// Education templates (Premium)
final List<Template> educationTemplates = [
  Template(
    id: 'calligraphy_copperplate',
    name: 'Kaligrafi Copperplate',
    nameEn: 'Copperplate Calligraphy',
    category: TemplateCategory.education,
    pattern: TemplatePattern.calligraphy,
    isPremium: true,
    spacingMm: 12,
    extraData: {
      'angleGuides': true,
      'angle': 55,
      'ratio': '3:2:3',
      'style': 'copperplate',
    },
  ),
  Template(
    id: 'math_grid',
    name: 'Matematik Kareli',
    nameEn: 'Math Grid',
    category: TemplateCategory.education,
    pattern: TemplatePattern.largeGrid,
    isPremium: true,
    spacingMm: 10,
    extraData: {
      'showRowNumbers': true,
      'showMargin': true,
    },
  ),
  Template(
    id: 'vocabulary',
    name: 'Kelime Listesi',
    nameEn: 'Vocabulary List',
    category: TemplateCategory.education,
    pattern: TemplatePattern.vocabularyList,
    isPremium: true,
    spacingMm: 8,
    extraData: {
      'columns': ['word', 'meaning', 'sentence'],
      'columnRatios': [0.25, 0.35, 0.40],
    },
  ),
];

/// Stationery templates (Mixed: some free, some premium)
final List<Template> stationeryTemplates = [
  Template(
    id: 'todo_priorities',
    name: 'Yapılacaklar',
    nameEn: 'To-Do List',
    category: TemplateCategory.stationery,
    pattern: TemplatePattern.todoList,
    isPremium: true,
    spacingMm: 10,
    extraData: {
      'showPriority': true,
      'priorityLevels': ['H', 'O', 'D'],
      'showCheckbox': true,
    },
  ),
  Template(
    id: 'checklist_simple',
    name: 'Kontrol Listesi',
    nameEn: 'Checklist',
    category: TemplateCategory.stationery,
    pattern: TemplatePattern.checklist,
    isPremium: false,
    spacingMm: 10,
    extraData: {
      'showCheckbox': true,
      'linesBetweenItems': 1,
    },
  ),
];
