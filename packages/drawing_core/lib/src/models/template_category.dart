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
  
  /// Math, Handwriting, Vocabulary - PREMIUM
  education,
  
  /// Calendar, Weekly, Budget - PREMIUM
  planning,
  
  /// Isometric, Hexagonal, Engineer - PREMIUM
  special,
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
      case TemplateCategory.education:
        return 'Eğitim';
      case TemplateCategory.planning:
        return 'Planlama';
      case TemplateCategory.special:
        return 'Özel';
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
      case TemplateCategory.education:
        return 'Education';
      case TemplateCategory.planning:
        return 'Planning';
      case TemplateCategory.special:
        return 'Special';
    }
  }
}
