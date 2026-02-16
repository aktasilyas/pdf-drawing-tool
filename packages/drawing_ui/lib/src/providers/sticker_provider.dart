import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for sticker placement mode.
class StickerPlacementState {
  /// The emoji/sticker selected for placement.
  final String? selectedEmoji;

  /// Whether the user is in placement mode (tap canvas to place).
  bool get isPlacing => selectedEmoji != null;

  const StickerPlacementState({this.selectedEmoji});

  StickerPlacementState copyWith({String? selectedEmoji, bool clearEmoji = false}) {
    return StickerPlacementState(
      selectedEmoji: clearEmoji ? null : (selectedEmoji ?? this.selectedEmoji),
    );
  }
}

/// Notifier for sticker placement state.
class StickerPlacementNotifier extends StateNotifier<StickerPlacementState> {
  StickerPlacementNotifier() : super(const StickerPlacementState());

  /// Enter placement mode with the given emoji.
  void selectEmoji(String emoji) {
    state = StickerPlacementState(selectedEmoji: emoji);
  }

  /// Called after the sticker has been placed on canvas.
  void placed() {
    state = const StickerPlacementState();
  }

  /// Cancel placement mode.
  void cancel() {
    state = const StickerPlacementState();
  }
}

/// Provider for sticker placement state.
final stickerPlacementProvider =
    StateNotifierProvider<StickerPlacementNotifier, StickerPlacementState>(
  (ref) => StickerPlacementNotifier(),
);
