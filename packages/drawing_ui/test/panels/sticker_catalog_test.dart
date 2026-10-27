import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/panels/sticker_catalog.dart';
import 'package:drawing_ui/src/panels/sticker_panel_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sticker catalog', () {
    test('has eight categories of 24 stickers each', () {
      expect(stickerCategories, hasLength(8));
      for (final category in stickerCategories) {
        final stickers = stickersForCategory(category);
        expect(stickers, hasLength(24), reason: category);
        expect(stickers.every((s) => s.isNotEmpty), isTrue, reason: category);
      }
    });

    test('keeps multi-codepoint emoji intact', () {
      expect(stickersForCategory('Emoji').first, '😀');
      expect(stickersForCategory('Semboller'), contains('🏳️‍🌈'));
      expect(stickersForCategory('Doğa').last, '🍃');
    });

    test('unknown category gets a placeholder', () {
      expect(stickersForCategory('nope'), ['❓']);
    });

    test('stickerAt is null outside the category', () {
      expect(stickerAt('Hayvanlar', 0), '🐶');
      expect(stickerAt('Hayvanlar', -1), isNull);
      expect(stickerAt('Hayvanlar', 24), isNull);
    });
  });

  group('StickerPanelActions', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      container.read(activePanelProvider.notifier).state = ToolType.sticker;
    });
    tearDown(() => container.dispose());

    StickerPanelActions actions() =>
        container.read(stickerPanelActionsProvider);

    test('place starts placement and closes the panel', () {
      actions().place('🐱');
      expect(container.read(stickerPlacementProvider).selectedEmoji, '🐱');
      expect(container.read(activePanelProvider), isNull);
    });

    test('placeSelected places the sticker at the index', () {
      expect(actions().placeSelected('Yiyecek', 1), isTrue);
      expect(container.read(stickerPlacementProvider).selectedEmoji, '🍊');
      expect(container.read(activePanelProvider), isNull);
    });

    test('placeSelected with nothing selected does nothing', () {
      expect(actions().placeSelected('Yiyecek', -1), isFalse);
      expect(container.read(stickerPlacementProvider).selectedEmoji, isNull);
      expect(container.read(activePanelProvider), ToolType.sticker);
    });
  });
}
