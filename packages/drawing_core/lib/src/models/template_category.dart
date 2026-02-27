/// Template kategorileri.
/// 
/// Basic kategorisi Free, diğerleri Premium.
enum TemplateCategory {
  /// Boş, çizgili, kareli, noktalı - FREE
  basic,
  
  /// Cornell, To-Do, Meeting Notes - PREMIUM
  productivity,
  
  /// Storyboard, Music, Art - PREMIUM
  creative,
  
  /// Isometric, Hexagonal, Calligraphy - PREMIUM
  special,

  /// Günlük, Haftalık, Aylık planlayıcı - PREMIUM
  planning,

  /// Bullet Journal, Gratitude, Diary - PREMIUM
  journal,

  /// Matematik, El yazısı, Kaligrafi, Kelime - PREMIUM
  education,

  /// To-Do, Checklist, Mektup, Tarif - PREMIUM
  stationery,
}

/// TemplateCategory extension methods
extension TemplateCategoryExtension on TemplateCategory {
  /// Kategori Free mi?
  bool get isFree => this == TemplateCategory.basic;
  
  /// Kategori Premium mı?
  bool get isPremium => !isFree;
  
  /// Türkçe kategori adı
  String get displayName {
    switch (this) {
      case TemplateCategory.basic:
        return 'Temel';
      case TemplateCategory.productivity:
        return 'Verimlilik';
      case TemplateCategory.creative:
        return 'Yaratıcı';
      case TemplateCategory.special:
        return 'Özel';
      case TemplateCategory.planning:
        return 'Planlama';
      case TemplateCategory.journal:
        return 'Günlük';
      case TemplateCategory.education:
        return 'Eğitim';
      case TemplateCategory.stationery:
        return 'Kırtasiye';
    }
  }

  /// İngilizce kategori adı
  String get displayNameEn {
    switch (this) {
      case TemplateCategory.basic:
        return 'Basic';
      case TemplateCategory.productivity:
        return 'Productivity';
      case TemplateCategory.creative:
        return 'Creative';
      case TemplateCategory.special:
        return 'Special';
      case TemplateCategory.planning:
        return 'Planning';
      case TemplateCategory.journal:
        return 'Journal';
      case TemplateCategory.education:
        return 'Education';
      case TemplateCategory.stationery:
        return 'Stationery';
    }
  }

  /// Kategorinin Material ikon adı (UI katmanında kullanılır)
  String get iconName {
    switch (this) {
      case TemplateCategory.basic:
        return 'description';
      case TemplateCategory.productivity:
        return 'work';
      case TemplateCategory.creative:
        return 'palette';
      case TemplateCategory.special:
        return 'star';
      case TemplateCategory.planning:
        return 'calendar_today';
      case TemplateCategory.journal:
        return 'auto_stories';
      case TemplateCategory.education:
        return 'school';
      case TemplateCategory.stationery:
        return 'checklist';
    }
  }
}
