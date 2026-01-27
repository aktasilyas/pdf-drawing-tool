import 'package:drawing_core/src/models/template_category.dart';
import 'package:drawing_core/src/models/template_pattern.dart';

/// Template model for page backgrounds.
///
/// Stores template metadata and styling information.
/// Colors are stored as int (ARGB) and should be overridden
/// by theme in the UI layer.
class Template {
  final String id;
  final String name;
  final String nameEn;
  final TemplateCategory category;
  final TemplatePattern pattern;
  final bool isPremium;
  final double spacingMm;
  final double lineWidth;
  final int defaultLineColor;
  final int defaultBackgroundColor;
  final Map<String, dynamic>? extraData;

  Template({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.pattern,
    this.isPremium = false,
    double? spacingMm,
    double? lineWidth,
    this.defaultLineColor = 0xFFE0E0E0,
    this.defaultBackgroundColor = 0xFFFFFFFF,
    this.extraData,
  })  : spacingMm = spacingMm ?? pattern.defaultSpacingMm,
        lineWidth = lineWidth ?? pattern.defaultLineWidth;

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String? ?? json['name'] as String,
      category: TemplateCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TemplateCategory.basic,
      ),
      pattern: TemplatePattern.values.firstWhere(
        (p) => p.name == json['pattern'],
        orElse: () => TemplatePattern.blank,
      ),
      isPremium: json['isPremium'] as bool? ?? false,
      spacingMm: (json['spacingMm'] as num?)?.toDouble(),
      lineWidth: (json['lineWidth'] as num?)?.toDouble(),
      defaultLineColor: json['defaultLineColor'] as int? ?? 0xFFE0E0E0,
      defaultBackgroundColor: json['defaultBackgroundColor'] as int? ?? 0xFFFFFFFF,
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'category': category.name,
    'pattern': pattern.name,
    'isPremium': isPremium,
    'spacingMm': spacingMm,
    'lineWidth': lineWidth,
    'defaultLineColor': defaultLineColor,
    'defaultBackgroundColor': defaultBackgroundColor,
    if (extraData != null) 'extraData': extraData,
  };

  Template copyWith({
    String? id,
    String? name,
    String? nameEn,
    TemplateCategory? category,
    TemplatePattern? pattern,
    bool? isPremium,
    double? spacingMm,
    double? lineWidth,
    int? defaultLineColor,
    int? defaultBackgroundColor,
    Map<String, dynamic>? extraData,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      pattern: pattern ?? this.pattern,
      isPremium: isPremium ?? this.isPremium,
      spacingMm: spacingMm ?? this.spacingMm,
      lineWidth: lineWidth ?? this.lineWidth,
      defaultLineColor: defaultLineColor ?? this.defaultLineColor,
      defaultBackgroundColor: defaultBackgroundColor ?? this.defaultBackgroundColor,
      extraData: extraData ?? this.extraData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Template && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
