import 'package:drawing_ui/src/l10n/drawing_strings.dart';
import 'package:drawing_ui/src/panels/sticker_catalog.dart';

/// Localized names for [StickerCategory].
extension StickerCategoryLabel on StickerCategory {
  /// The user-facing name of this category in the given strings.
  String label(DrawingStrings s) {
    final c = s.catalog;
    switch (this) {
      case StickerCategory.emoji:
        return c.stickerEmoji;
      case StickerCategory.animals:
        return c.stickerAnimals;
      case StickerCategory.food:
        return c.stickerFood;
      case StickerCategory.travel:
        return c.stickerTravel;
      case StickerCategory.objects:
        return c.stickerObjects;
      case StickerCategory.symbols:
        return c.stickerSymbols;
      case StickerCategory.hands:
        return c.stickerHands;
      case StickerCategory.nature:
        return c.stickerNature;
    }
  }
}
