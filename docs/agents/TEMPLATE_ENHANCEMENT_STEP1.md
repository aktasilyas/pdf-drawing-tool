# TEMPLATE ENHANCEMENT — STEP 1: Enum Genişletme + Template Tanımları

## BRANCH
```bash
git checkout main
git pull origin main
git checkout -b feature/template-enhancement
```

## KRİTİK KURALLAR
1. MEVCUT ENUM DEĞERLERİNİ ASLA SİLME VEYA YENİDEN SIRALAMA — sadece sona ekle
2. MEVCUT TEMPLATE TANIMLARINI DEĞİŞTİRME — sadece yeni ekle
3. HARD CODED RENK KULLANMA — defaultLineColor ve defaultBackgroundColor "önerilen varsayılan" olarak kal, UI katmanı bunları theme'dan override edecek. Template model'deki renk alanları sadece fallback.
4. Testleri çalıştır, hata bırakma

---

## GÖREV 1: TemplateCategory Genişlet

**Dosya:** `packages/drawing_core/lib/src/models/template_category.dart`

Mevcut enum'a 4 yeni değer EKLE (mevcut sıralama korunacak):

```dart
enum TemplateCategory {
  // === MEVCUT — DOKUNMA ===
  basic,
  productivity,
  creative,
  special,
  
  // === YENİ — SONA EKLE ===
  planning,     // Günlük, Haftalık, Aylık planlayıcı
  journal,      // Bullet Journal, Gratitude, Diary
  education,    // Matematik, El yazısı, Kaligrafi, Kelime
  stationery,   // To-Do, Checklist, Mektup, Tarif
}
```

TemplateCategoryExtension'a yeni değerleri ekle:

```dart
extension TemplateCategoryExtension on TemplateCategory {
  bool get isFree => this == TemplateCategory.basic;
  bool get isPremium => !isFree;
  
  String get displayName {
    switch (this) {
      case TemplateCategory.basic: return 'Temel';
      case TemplateCategory.productivity: return 'Verimlilik';
      case TemplateCategory.creative: return 'Yaratıcı';
      case TemplateCategory.special: return 'Özel';
      // YENİ:
      case TemplateCategory.planning: return 'Planlama';
      case TemplateCategory.journal: return 'Günlük';
      case TemplateCategory.education: return 'Eğitim';
      case TemplateCategory.stationery: return 'Kırtasiye';
    }
  }
  
  String get displayNameEn {
    switch (this) {
      case TemplateCategory.basic: return 'Basic';
      case TemplateCategory.productivity: return 'Productivity';
      case TemplateCategory.creative: return 'Creative';
      case TemplateCategory.special: return 'Special';
      // YENİ:
      case TemplateCategory.planning: return 'Planning';
      case TemplateCategory.journal: return 'Journal';
      case TemplateCategory.education: return 'Education';
      case TemplateCategory.stationery: return 'Stationery';
    }
  }
  
  /// Kategorinin Material ikonu (UI katmanında kullanılır)
  /// IconData döndüremiyoruz (pure Dart), bu yüzden string icon adı
  String get iconName {
    switch (this) {
      case TemplateCategory.basic: return 'description';
      case TemplateCategory.productivity: return 'work';
      case TemplateCategory.creative: return 'palette';
      case TemplateCategory.special: return 'star';
      case TemplateCategory.planning: return 'calendar_today';
      case TemplateCategory.journal: return 'auto_stories';
      case TemplateCategory.education: return 'school';
      case TemplateCategory.stationery: return 'checklist';
    }
  }
}
```

---

## GÖREV 2: TemplatePattern Genişlet

**Dosya:** `packages/drawing_core/lib/src/models/template_pattern.dart`

Mevcut 16 enum'a 12 yeni değer EKLE (mevcutlara DOKUNMA):

```dart
enum TemplatePattern {
  // === MEVCUT 16 — DOKUNMA ===
  blank,
  thinLines,
  mediumLines,
  thickLines,
  smallGrid,
  mediumGrid,
  largeGrid,
  smallDots,
  mediumDots,
  largeDots,
  cornell,
  music,
  handwriting,
  calligraphy,
  isometric,
  hexagonal,

  // === YENİ 12 — SONA EKLE ===
  dailyPlanner,
  weeklyPlanner,
  monthlyPlanner,
  bulletJournal,
  gratitudeJournal,
  todoList,
  checklist,
  storyboard,
  wireframe,
  meetingNotes,
  readingLog,
  vocabularyList,
}
```

TemplatePatternExtension'a yeni değerlerin property'lerini ekle. Mevcut extension property'lerini kontrol et ve yeni enum'ları uygun şekilde kategorize et:

- `hasLines`: meetingNotes, readingLog → true
- `hasGrid`: monthlyPlanner, storyboard, wireframe → true  
- `hasDots`: hiçbiri
- `isStructured` (YENİ property ekle): tüm 12 yeni pattern → true, mevcut 16 → false

```dart
/// Bu pattern yapısal mı (header, bölge, checkbox içerir)?
bool get isStructured {
  switch (this) {
    case TemplatePattern.dailyPlanner:
    case TemplatePattern.weeklyPlanner:
    case TemplatePattern.monthlyPlanner:
    case TemplatePattern.bulletJournal:
    case TemplatePattern.gratitudeJournal:
    case TemplatePattern.todoList:
    case TemplatePattern.checklist:
    case TemplatePattern.storyboard:
    case TemplatePattern.wireframe:
    case TemplatePattern.meetingNotes:
    case TemplatePattern.readingLog:
    case TemplatePattern.vocabularyList:
      return true;
    default:
      return false;
  }
}
```

Yeni pattern'ların `defaultSpacingMm` ve `defaultLineWidth` değerleri:

| Pattern | defaultSpacingMm | defaultLineWidth |
|---------|-------------------|------------------|
| dailyPlanner | 8 | 0.5 |
| weeklyPlanner | 8 | 0.5 |
| monthlyPlanner | 8 | 0.5 |
| bulletJournal | 7 | 0.3 |
| gratitudeJournal | 8 | 0.5 |
| todoList | 10 | 0.5 |
| checklist | 10 | 0.5 |
| storyboard | 0 | 0.5 |
| wireframe | 5 | 0.3 |
| meetingNotes | 8 | 0.5 |
| readingLog | 8 | 0.5 |
| vocabularyList | 8 | 0.5 |

---

## GÖREV 3: TemplateRegistry'ye Yeni Template'lar Ekle

**Dosya:** `packages/drawing_core/lib/src/services/template_registry.dart`

Mevcut template listelerine DOKUNMA. Yeni template'ları yeni static listeler olarak ekle.

⚠️ RENK UYARISI: `defaultLineColor` ve `defaultBackgroundColor` değerleri sadece fallback'tir. UI katmanı bu renkleri theme'dan override edecek. Hard coded renk KULLANMA demek değil burada renk yok demek — aksine, makul varsayılanlar ver ama bunların UI'da theme ile değiştirileceğini bil.

```dart
  // === MEVCUT LİSTELER — DOKUNMA ===
  // basicTemplates, productivityTemplates, creativeTemplates, specialTemplates

  // === YENİ LİSTELER ===

  /// Planning templates (Premium)
  static final List<Template> planningTemplates = [
    Template(
      id: 'daily_planner',
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
      id: 'weekly_planner',
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
    Template(
      id: 'study_planner',
      name: 'Ders Programı',
      nameEn: 'Study Planner',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.weeklyPlanner,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'startDay': 'monday',
        'showPeriods': true,
        'periodsPerDay': 8,
      },
    ),
    Template(
      id: 'habit_tracker',
      name: 'Alışkanlık Takip',
      nameEn: 'Habit Tracker',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.monthlyPlanner,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'rows': 10,
        'days': 30,
        'showLabels': true,
      },
    ),
    Template(
      id: 'goal_setting',
      name: 'Hedef Belirleme',
      nameEn: 'Goal Setting',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.bulletJournal,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'sections': ['mainGoal', 'subGoals', 'timeline', 'notes'],
      },
    ),
    Template(
      id: 'pomodoro',
      name: 'Pomodoro',
      nameEn: 'Pomodoro Timer',
      category: TemplateCategory.planning,
      pattern: TemplatePattern.dailyPlanner,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'blockMinutes': 25,
        'breakMinutes': 5,
        'blocksPerRow': 4,
      },
    ),
  ];

  /// Journal templates (Premium)
  static final List<Template> journalTemplates = [
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
      id: 'diary',
      name: 'Günlük',
      nameEn: 'Diary',
      category: TemplateCategory.journal,
      pattern: TemplatePattern.meetingNotes,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'showDateHeader': true,
        'showWeather': true,
        'showMood': true,
      },
    ),
    Template(
      id: 'mood_tracker',
      name: 'Ruh Hali Takip',
      nameEn: 'Mood Tracker',
      category: TemplateCategory.journal,
      pattern: TemplatePattern.monthlyPlanner,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'moodLevels': 5,
        'days': 30,
        'showEmoji': true,
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
    Template(
      id: 'dream_journal',
      name: 'Rüya Günlüğü',
      nameEn: 'Dream Journal',
      category: TemplateCategory.journal,
      pattern: TemplatePattern.gratitudeJournal,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'sections': ['dream', 'symbols', 'interpretation'],
        'showDateHeader': true,
      },
    ),
  ];

  /// Education templates (Premium)
  static final List<Template> educationTemplates = [
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
      id: 'calligraphy_italic',
      name: 'Kaligrafi İtalik',
      nameEn: 'Italic Calligraphy',
      category: TemplateCategory.education,
      pattern: TemplatePattern.calligraphy,
      isPremium: true,
      spacingMm: 12,
      extraData: {
        'angleGuides': true,
        'angle': 45,
        'nibWidths': 5,
        'style': 'italic',
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
    Template(
      id: 'flashcard_grid',
      name: 'Flashcard Grid',
      nameEn: 'Flashcard Grid',
      category: TemplateCategory.education,
      pattern: TemplatePattern.largeGrid,
      isPremium: true,
      spacingMm: 10,
      extraData: {
        'cardRows': 3,
        'cardCols': 2,
        'showDivider': true,
      },
    ),
  ];

  /// Stationery templates (Premium)
  static final List<Template> stationeryTemplates = [
    Template(
      id: 'todo_list',
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
      isPremium: false, // Bu FREE olsun — basit ve yaygın
      spacingMm: 10,
      extraData: {
        'showCheckbox': true,
        'linesBetweenItems': 1,
      },
    ),
    Template(
      id: 'shopping_list',
      name: 'Alışveriş Listesi',
      nameEn: 'Shopping List',
      category: TemplateCategory.stationery,
      pattern: TemplatePattern.checklist,
      isPremium: true,
      spacingMm: 10,
      extraData: {
        'showCategory': true,
        'categories': ['Meyve/Sebze', 'Et/Balık', 'Süt Ürünleri', 'Diğer'],
      },
    ),
    Template(
      id: 'letter_formal',
      name: 'Resmi Mektup',
      nameEn: 'Formal Letter',
      category: TemplateCategory.stationery,
      pattern: TemplatePattern.meetingNotes,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'sections': ['senderAddress', 'date', 'recipientAddress', 'greeting', 'body', 'closing'],
      },
    ),
    Template(
      id: 'recipe_card',
      name: 'Tarif Kartı',
      nameEn: 'Recipe Card',
      category: TemplateCategory.stationery,
      pattern: TemplatePattern.readingLog,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'sections': ['title', 'ingredients', 'instructions', 'notes'],
        'showServings': true,
        'showTime': true,
      },
    ),
    Template(
      id: 'budget_tracker',
      name: 'Bütçe Takip',
      nameEn: 'Budget Tracker',
      category: TemplateCategory.stationery,
      pattern: TemplatePattern.vocabularyList,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'columns': ['description', 'income', 'expense', 'balance'],
        'columnRatios': [0.40, 0.20, 0.20, 0.20],
        'showTotals': true,
      },
    ),
  ];
```

### `all` listesini güncelle:

```dart
  static final List<Template> all = [
    ...basicTemplates,        // Mevcut
    ...productivityTemplates, // Mevcut
    ...creativeTemplates,     // Mevcut
    ...specialTemplates,      // Mevcut
    // YENİ:
    ...planningTemplates,
    ...journalTemplates,
    ...educationTemplates,
    ...stationeryTemplates,
  ];
```

### basic template'lara 2 yeni ekle:

Mevcut `basicTemplates` listesinin SONUNA ekle (mevcut 6'ya dokunma):

```dart
    // === MEVCUT 6 TEMPLATE AYNEN KALACAK ===
    // blank, thin_lined, grid, small_grid, dotted, cornell
    
    // === YENİ 2 BASIC TEMPLATE EKLE ===
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
```

### creative template'lara ekle:

Mevcut `creativeTemplates` listesinin SONUNA (mevcut 3'e dokunma):

```dart
    // === MEVCUT 3 AYNEN KALACAK ===
    // music_staff, storyboard (yoksa), handwriting_practice
    
    // === YENİ CREATIVE TEMPLATE'LAR EKLE ===
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
      extraData: {
        'aspectRatio': '16:9',
        'framesPerPage': 6,
        'showDescription': true,
        'showShotNumber': true,
      },
    ),
    Template(
      id: 'storyboard_4_3',
      name: 'Storyboard 4:3',
      nameEn: 'Storyboard 4:3',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.storyboard,
      isPremium: true,
      extraData: {
        'aspectRatio': '4:3',
        'framesPerPage': 6,
        'showDescription': true,
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
    Template(
      id: 'wireframe_tablet',
      name: 'Tablet Wireframe',
      nameEn: 'Tablet Wireframe',
      category: TemplateCategory.creative,
      pattern: TemplatePattern.wireframe,
      isPremium: true,
      spacingMm: 5,
      extraData: {
        'deviceType': 'tablet',
        'framesPerPage': 2,
        'showGrid': true,
      },
    ),
```

### productivity template'lara ekle:

Mevcut `productivityTemplates` listesinin SONUNA:

```dart
    // === MEVCUT AYNEN KALACAK ===
    
    // === YENİ PRODUCTIVITY EKLE ===
    Template(
      id: 'meeting_notes',
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
    Template(
      id: 'lecture_notes',
      name: 'Ders Notları',
      nameEn: 'Lecture Notes',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'showDateHeader': true,
        'showSubjectHeader': true,
        'showPageNumber': true,
      },
    ),
    Template(
      id: 'two_column',
      name: 'İki Sütun',
      nameEn: 'Two Column',
      category: TemplateCategory.productivity,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 8,
      extraData: {
        'columnCount': 2,
        'columnRatio': 0.5,
        'showDivider': true,
      },
    ),
```

### special template'lara ekle:

Mevcut `specialTemplates` listesinin SONUNA:

```dart
    // === MEVCUT 3 AYNEN KALACAK ===
    // isometric, hexagonal, calligraphy
    
    // === YENİ SPECIAL EKLE ===
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
      id: 'legal_pad',
      name: 'Legal Pad',
      nameEn: 'Legal Pad',
      category: TemplateCategory.special,
      pattern: TemplatePattern.mediumLines,
      isPremium: true,
      spacingMm: 8,
      defaultBackgroundColor: 0xFFFFF8DC, // Açık sarı (legal pad klasik rengi) — UI override edebilir
      extraData: {
        'showMarginLeft': true,
        'marginMm': 30,
        'variant': 'legal',
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
```

---

## GÖREV 4: Testleri Güncelle

**Dosya:** `packages/drawing_core/test/` altındaki ilgili test dosyaları

### template_category test:
```dart
test('should have 8 categories', () {
  expect(TemplateCategory.values.length, 8);
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
```

### template_pattern test:
```dart
test('should have 28 patterns', () {
  expect(TemplatePattern.values.length, 28);
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
```

### template_registry test:
```dart
test('should have 51+ templates total', () {
  expect(TemplateRegistry.all.length, greaterThanOrEqualTo(51));
});

test('should have 8+ basic (free) templates', () {
  final free = TemplateRegistry.getFreeTemplates();
  expect(free.length, greaterThanOrEqualTo(8));
});

test('should have templates for all 8 categories', () {
  for (final cat in TemplateCategory.values) {
    final templates = TemplateRegistry.getByCategory(cat);
    expect(templates, isNotEmpty, reason: '${cat.name} has no templates');
  }
});

test('all template IDs should be unique', () {
  final ids = TemplateRegistry.all.map((t) => t.id).toSet();
  expect(ids.length, TemplateRegistry.all.length);
});

test('planning templates should exist', () {
  final planning = TemplateRegistry.getByCategory(TemplateCategory.planning);
  expect(planning.length, 7);
});

test('journal templates should exist', () {
  final journal = TemplateRegistry.getByCategory(TemplateCategory.journal);
  expect(journal.length, 6);
});

test('stationery templates should exist', () {
  final stationery = TemplateRegistry.getByCategory(TemplateCategory.stationery);
  expect(stationery.length, 6);
});

test('education templates should exist', () {
  final edu = TemplateRegistry.getByCategory(TemplateCategory.education);
  expect(edu.length, 5);
});

// checklist_simple free olmalı
test('checklist should be free', () {
  final checklist = TemplateRegistry.getById('checklist_simple');
  expect(checklist, isNotNull);
  expect(checklist!.isPremium, false);
});
```

---

## GÖREV 5: Barrel Exports Kontrol

drawing_core barrel export'unda yeni enum değerleri otomatik olarak gelir (mevcut dosyalar güncelleniyor, yeni dosya oluşturmuyoruz). Kontrol et:
- `packages/drawing_core/lib/drawing_core.dart` dosyasında template_category, template_pattern, template_registry export ediliyor mu?

---

## SON KONTROL

```bash
cd packages/drawing_core
flutter analyze
flutter test

cd ../../example_app
flutter analyze
```

Hata yoksa commit:

```bash
git add -A
git commit -m "feat(core): expand templates to 51+ with 8 categories

- Add 4 new categories: planning, journal, education, stationery
- Add 12 new structural patterns (planner, todo, journal, etc.)
- Add 35 new template definitions across all categories
- Add isStructured property to TemplatePattern
- Add iconName property to TemplateCategory
- Update tests for new enums and templates
- Backward compatible: existing templates unchanged"
```

⚠️ Commit ETMEDEN ÖNCE İlyas'a bildir ve onay al.

---

## BU ADIMDA YAPILMAYACAKLAR
- Painter oluşturma (Step 2'de)
- UI değişikliği (Step 3'te)
- Supabase entegrasyonu (Step 4'te)
- Renk/tema değişikliği (renkler theme'dan gelecek, Step 2-3'te)
