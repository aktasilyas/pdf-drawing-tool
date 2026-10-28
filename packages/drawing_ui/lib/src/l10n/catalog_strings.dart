/// User-facing copy of the shape and sticker panels.
///
/// Every getter must also be listed in [toMap]; the drift tests rely on it.
abstract class CatalogStrings {
  const CatalogStrings();

  /// Shapes panel title.
  String get shapesTitle;

  /// Shape outline width.
  String get strokeWidth;

  /// Shape outline color.
  String get strokeColor;

  /// Shape fill toggle.
  String get fillShape;

  /// Shape fill color.
  String get fillColor;

  /// Name of the line shape.
  String get shapeLine;

  /// Name of the arrow shape.
  String get shapeArrow;

  /// Name of the rectangle shape.
  String get shapeRectangle;

  /// Name of the ellipse shape.
  String get shapeEllipse;

  /// Name of the triangle shape.
  String get shapeTriangle;

  /// Name of the diamond shape.
  String get shapeDiamond;

  /// Name of the star shape.
  String get shapeStar;

  /// Name of the pentagon shape.
  String get shapePentagon;

  /// Name of the hexagon shape.
  String get shapeHexagon;

  /// Name of the plus shape.
  String get shapePlus;

  /// Sticker panel title.
  String get stickersTitle;

  /// Add sticker button.
  String get addSticker;

  /// Sticker category: emoji.
  String get stickerEmoji;

  /// Sticker category: animals.
  String get stickerAnimals;

  /// Sticker category: food.
  String get stickerFood;

  /// Sticker category: travel.
  String get stickerTravel;

  /// Sticker category: objects.
  String get stickerObjects;

  /// Sticker category: symbols.
  String get stickerSymbols;

  /// Sticker category: hands.
  String get stickerHands;

  /// Sticker category: nature.
  String get stickerNature;

  /// Every getter by name, for drift tests.
  Map<String, String> toMap() => {
        'shapesTitle': shapesTitle,
        'strokeWidth': strokeWidth,
        'strokeColor': strokeColor,
        'fillShape': fillShape,
        'fillColor': fillColor,
        'shapeLine': shapeLine,
        'shapeArrow': shapeArrow,
        'shapeRectangle': shapeRectangle,
        'shapeEllipse': shapeEllipse,
        'shapeTriangle': shapeTriangle,
        'shapeDiamond': shapeDiamond,
        'shapeStar': shapeStar,
        'shapePentagon': shapePentagon,
        'shapeHexagon': shapeHexagon,
        'shapePlus': shapePlus,
        'stickersTitle': stickersTitle,
        'addSticker': addSticker,
        'stickerEmoji': stickerEmoji,
        'stickerAnimals': stickerAnimals,
        'stickerFood': stickerFood,
        'stickerTravel': stickerTravel,
        'stickerObjects': stickerObjects,
        'stickerSymbols': stickerSymbols,
        'stickerHands': stickerHands,
        'stickerNature': stickerNature,
      };
}

/// Turkish copy: the default when no scope is installed.
class CatalogStringsTr extends CatalogStrings {
  const CatalogStringsTr();

  @override
  String get shapesTitle => 'Şekil';

  @override
  String get strokeWidth => 'Kontur Kalınlığı';

  @override
  String get strokeColor => 'Kontur Rengi';

  @override
  String get fillShape => 'Şekil dolgusu';

  @override
  String get fillColor => 'Dolgu Rengi';

  @override
  String get shapeLine => 'Çizgi';

  @override
  String get shapeArrow => 'Ok';

  @override
  String get shapeRectangle => 'Dikdörtgen';

  @override
  String get shapeEllipse => 'Elips';

  @override
  String get shapeTriangle => 'Üçgen';

  @override
  String get shapeDiamond => 'Eşkenar dörtgen';

  @override
  String get shapeStar => 'Yıldız';

  @override
  String get shapePentagon => 'Beşgen';

  @override
  String get shapeHexagon => 'Altıgen';

  @override
  String get shapePlus => 'Artı';

  @override
  String get stickersTitle => 'Çıkartmalar';

  @override
  String get addSticker => 'Çıkartma Ekle';

  @override
  String get stickerEmoji => 'Emoji';

  @override
  String get stickerAnimals => 'Hayvanlar';

  @override
  String get stickerFood => 'Yiyecek';

  @override
  String get stickerTravel => 'Seyahat';

  @override
  String get stickerObjects => 'Nesneler';

  @override
  String get stickerSymbols => 'Semboller';

  @override
  String get stickerHands => 'Eller';

  @override
  String get stickerNature => 'Doğa';
}
