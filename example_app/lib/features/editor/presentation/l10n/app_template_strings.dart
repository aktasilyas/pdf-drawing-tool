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

  // Keyed by the persisted cover id (CoverRegistry.all); a test fails when
  // a registry cover has no case here.
  @override
  String coverName(Cover cover) => switch (cover.id) {
        'solid_navy' => _l10n.editorCoverSolidNavy,
        'solid_burgundy' => _l10n.editorCoverSolidBurgundy,
        'minimal_gray' => _l10n.editorCoverMinimalGray,
        'pattern_dots' => _l10n.editorCoverPatternDots,
        'pattern_lines' => _l10n.editorCoverPatternLines,
        'gradient_sunset' => _l10n.editorCoverGradientSunset,
        'gradient_ocean' => _l10n.editorCoverGradientOcean,
        'gradient_forest' => _l10n.editorCoverGradientForest,
        'gradient_purple' => _l10n.editorCoverGradientPurple,
        'img_kraft' => _l10n.editorCoverImgKraft,
        'img_geometric' => _l10n.editorCoverImgGeometric,
        'img_terrazzo' => _l10n.editorCoverImgTerrazzo,
        'img_dinosaur' => _l10n.editorCoverImgDinosaur,
        'img_space' => _l10n.editorCoverImgSpace,
        'img_floral' => _l10n.editorCoverImgFloral,
        'img_navy_gold' => _l10n.editorCoverImgNavyGold,
        'img_leather' => _l10n.editorCoverImgLeather,
        'linen_sage' => _l10n.editorCoverLinenSage,
        'linen_sand' => _l10n.editorCoverLinenSand,
        'linen_slate' => _l10n.editorCoverLinenSlate,
        'leather_oxblood' => _l10n.editorCoverLeatherOxblood,
        'leather_cognac' => _l10n.editorCoverLeatherCognac,
        'leather_navy' => _l10n.editorCoverLeatherNavy,
        'kraft_natural' => _l10n.editorCoverKraftNatural,
        'kraft_charcoal' => _l10n.editorCoverKraftCharcoal,
        'felt_mustard' => _l10n.editorCoverFeltMustard,
        'felt_dusty_rose' => _l10n.editorCoverFeltDustyRose,
        _ => cover.name,
      };

  // Same rule as the library's `localizedName`; the editor must not import
  // documents/presentation.
  bool get _isTurkish => _l10n.localeName.startsWith('tr');
}
