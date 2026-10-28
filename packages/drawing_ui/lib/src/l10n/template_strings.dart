import 'package:drawing_core/drawing_core.dart';

/// User-facing copy of the template picker, paper options and backgrounds.
///
/// Every getter and method must also be listed in [toMap]; the drift tests
/// rely on it. Parameterized strings are called with a fixed sample there.
abstract class TemplateStrings {
  const TemplateStrings();

  String get allCategories;
  String get coverTab;
  String get paperTab;
  String get apply;
  String get portrait;
  String get landscape;
  String get paperSquare;
  String get paperWidescreen;
  String get custom;
  String get colorWhite;
  String get colorCream;
  String get colorBlack;
  String get colorYellow;
  String get templatesHeader;
  String get background;
  String get backgroundPattern;
  String get patternPlain;
  String get patternDotted;
  String get patternGrid;
  String get backgroundColor;

  /// Display name of a template in the active language.
  String templateName(Template template);

  /// Display name of a template category in the active language.
  String categoryName(TemplateCategory category);

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'allCategories': allCategories,
        'coverTab': coverTab,
        'paperTab': paperTab,
        'apply': apply,
        'portrait': portrait,
        'landscape': landscape,
        'paperSquare': paperSquare,
        'paperWidescreen': paperWidescreen,
        'custom': custom,
        'colorWhite': colorWhite,
        'colorCream': colorCream,
        'colorBlack': colorBlack,
        'colorYellow': colorYellow,
        'templatesHeader': templatesHeader,
        'background': background,
        'backgroundPattern': backgroundPattern,
        'patternPlain': patternPlain,
        'patternDotted': patternDotted,
        'patternGrid': patternGrid,
        'backgroundColor': backgroundColor,
        'templateName': templateName(TemplateRegistry.blank),
        'categoryName': categoryName(TemplateCategory.basic),
      };
}

/// Turkish copy: the default when no scope is installed.
class TemplateStringsTr extends TemplateStrings {
  const TemplateStringsTr();

  @override
  String get allCategories => 'Tümü';

  @override
  String get coverTab => 'Kapak';

  @override
  String get paperTab => 'Kâğıt';

  @override
  String get apply => 'Uygula';

  @override
  String get portrait => 'Dikey';

  @override
  String get landscape => 'Yatay';

  @override
  String get paperSquare => 'Kare';

  @override
  String get paperWidescreen => 'Geniş (16:9)';

  @override
  String get custom => 'Özel';

  @override
  String get colorWhite => 'Beyaz';

  @override
  String get colorCream => 'Krem';

  @override
  String get colorBlack => 'Siyah';

  @override
  String get colorYellow => 'Sarı';

  @override
  String get templatesHeader => 'Şablonlar';

  @override
  String get background => 'Arka Plan';

  @override
  String get backgroundPattern => 'Arka Plan Deseni';

  @override
  String get patternPlain => 'Düz';

  @override
  String get patternDotted => 'Noktalı';

  @override
  String get patternGrid => 'Izgara';

  @override
  String get backgroundColor => 'Arka Plan Rengi';

  @override
  String templateName(Template template) => template.name;

  @override
  String categoryName(TemplateCategory category) => category.displayName;
}
