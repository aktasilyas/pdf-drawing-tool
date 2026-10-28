import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [TemplateStrings] backed by the generated [AppLocalizations].
class AppTemplateStrings extends TemplateStrings {
  const AppTemplateStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get allCategories => _l10n.editorTemplateAllCategories;

  @override
  String get coverTab => _l10n.editorTemplateCoverTab;

  @override
  String get paperTab => _l10n.editorTemplatePaperTab;

  @override
  String get apply => _l10n.editorTemplateApply;

  @override
  String get portrait => _l10n.editorTemplatePortrait;

  @override
  String get landscape => _l10n.editorTemplateLandscape;

  @override
  String get paperSquare => _l10n.editorTemplatePaperSquare;

  @override
  String get paperWidescreen => _l10n.editorTemplatePaperWidescreen;

  @override
  String get custom => _l10n.editorTemplateCustom;

  @override
  String get colorWhite => _l10n.editorTemplateColorWhite;

  @override
  String get colorCream => _l10n.editorTemplateColorCream;

  @override
  String get colorBlack => _l10n.editorTemplateColorBlack;

  @override
  String get colorYellow => _l10n.editorTemplateColorYellow;

  @override
  String get templatesHeader => _l10n.editorTemplateTemplatesHeader;

  @override
  String get background => _l10n.editorTemplateBackground;

  @override
  String get backgroundPattern => _l10n.editorTemplateBackgroundPattern;

  @override
  String get patternPlain => _l10n.editorTemplatePatternPlain;

  @override
  String get patternDotted => _l10n.editorTemplatePatternDotted;

  @override
  String get patternGrid => _l10n.editorTemplatePatternGrid;

  @override
  String get backgroundColor => _l10n.editorTemplateBackgroundColor;

  @override
  String templateName(Template template) =>
      _isTurkish ? template.name : template.nameEn;

  @override
  String categoryName(TemplateCategory category) =>
      _isTurkish ? category.displayName : category.displayNameEn;

  // Same rule as the library's `localizedName`; the editor must not import
  // documents/presentation.
  bool get _isTurkish => _l10n.localeName.startsWith('tr');
}
