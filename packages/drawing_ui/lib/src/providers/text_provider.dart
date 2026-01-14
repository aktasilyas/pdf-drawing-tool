import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

/// Text tool state
class TextToolState {
  final bool isEditing;
  final TextElement? activeText;
  final bool isNewText; // true = yeni oluşturuluyor, false = mevcut düzenleniyor

  const TextToolState({
    this.isEditing = false,
    this.activeText,
    this.isNewText = true,
  });

  TextToolState copyWith({
    bool? isEditing,
    TextElement? activeText,
    bool? isNewText,
  }) {
    return TextToolState(
      isEditing: isEditing ?? this.isEditing,
      activeText: activeText ?? this.activeText,
      isNewText: isNewText ?? this.isNewText,
    );
  }
}

/// Text tool notifier
class TextToolNotifier extends StateNotifier<TextToolState> {
  TextToolNotifier() : super(const TextToolState());

  /// Yeni text oluşturmaya başla
  void startNewText(
    double x,
    double y, {
    double fontSize = 16.0,
    int color = 0xFF000000,
  }) {
    final text = TextElement.create(
      text: '',
      x: x,
      y: y,
      fontSize: fontSize,
      color: color,
    );

    state = TextToolState(
      isEditing: true,
      activeText: text,
      isNewText: true,
    );
  }

  /// Mevcut text'i düzenlemeye başla
  void editExistingText(TextElement text) {
    state = TextToolState(
      isEditing: true,
      activeText: text,
      isNewText: false,
    );
  }

  /// Text içeriğini güncelle
  void updateText(TextElement updatedText) {
    state = state.copyWith(activeText: updatedText);
  }

  /// Düzenlemeyi bitir
  TextElement? finishEditing() {
    final result = state.activeText;
    state = const TextToolState();
    return result;
  }

  /// Düzenlemeyi iptal et
  void cancelEditing() {
    state = const TextToolState();
  }
}

/// Text tool provider
final textToolProvider =
    StateNotifierProvider<TextToolNotifier, TextToolState>((ref) {
  return TextToolNotifier();
});

/// Aktif layer'daki texts
final activeLayerTextsProvider = Provider<List<TextElement>>((ref) {
  final document = ref.watch(documentProvider);
  if (document.layers.isEmpty) return [];
  return document.layers[document.activeLayerIndex].texts;
});
