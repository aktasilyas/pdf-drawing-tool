import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [CatalogStrings] backed by the generated [AppLocalizations].
class AppCatalogStrings extends CatalogStrings {
  const AppCatalogStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get shapesTitle => _l10n.editorCatalogShapesTitle;

  @override
  String get strokeWidth => _l10n.editorCatalogStrokeWidth;

  @override
  String get strokeColor => _l10n.editorCatalogStrokeColor;

  @override
  String get fillShape => _l10n.editorCatalogFillShape;

  @override
  String get fillColor => _l10n.editorCatalogFillColor;

  @override
  String get shapeLine => _l10n.editorCatalogShapeLine;

  @override
  String get shapeArrow => _l10n.editorCatalogShapeArrow;

  @override
  String get shapeRectangle => _l10n.editorCatalogShapeRectangle;

  @override
  String get shapeEllipse => _l10n.editorCatalogShapeEllipse;

  @override
  String get shapeTriangle => _l10n.editorCatalogShapeTriangle;

  @override
  String get shapeDiamond => _l10n.editorCatalogShapeDiamond;

  @override
  String get shapeStar => _l10n.editorCatalogShapeStar;

  @override
  String get shapePentagon => _l10n.editorCatalogShapePentagon;

  @override
  String get shapeHexagon => _l10n.editorCatalogShapeHexagon;

  @override
  String get shapePlus => _l10n.editorCatalogShapePlus;

  @override
  String get stickersTitle => _l10n.editorCatalogStickersTitle;

  @override
  String get addSticker => _l10n.editorCatalogAddSticker;

  @override
  String get stickerEmoji => _l10n.editorCatalogStickerEmoji;

  @override
  String get stickerAnimals => _l10n.editorCatalogStickerAnimals;

  @override
  String get stickerFood => _l10n.editorCatalogStickerFood;

  @override
  String get stickerTravel => _l10n.editorCatalogStickerTravel;

  @override
  String get stickerObjects => _l10n.editorCatalogStickerObjects;

  @override
  String get stickerSymbols => _l10n.editorCatalogStickerSymbols;

  @override
  String get stickerHands => _l10n.editorCatalogStickerHands;

  @override
  String get stickerNature => _l10n.editorCatalogStickerNature;
}
