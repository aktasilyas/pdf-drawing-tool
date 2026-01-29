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
    }
  }
}
