import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/panels/sticker_catalog.dart';
import 'package:drawing_ui/src/providers/sticker_provider.dart';
import 'package:drawing_ui/src/providers/tool_providers.dart';

/// Decisions behind the sticker panel's buttons, kept out of the widgets.
class StickerPanelActions {
  /// Creates the actions bound to [_ref].
  StickerPanelActions(this._ref);

  final Ref _ref;

  /// Enters sticker placement mode with [emoji] (tap the canvas to place it)
  /// and closes the panel.
  void place(String emoji) {
    _ref.read(stickerPlacementProvider.notifier).selectEmoji(emoji);
    _ref.read(activePanelProvider.notifier).state = null;
  }

  /// Places the sticker at [index] of [category]. Does nothing and returns
  /// `false` when nothing valid is selected.
  bool placeSelected(String category, int index) {
    final emoji = stickerAt(category, index);
    if (emoji == null) return false;
    place(emoji);
    return true;
  }
}

/// Sticker panel actions.
final stickerPanelActionsProvider =
    Provider<StickerPanelActions>(StickerPanelActions.new);
