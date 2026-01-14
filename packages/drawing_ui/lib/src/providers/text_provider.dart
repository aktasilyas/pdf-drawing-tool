import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

/// Text tool state
class TextToolState {
  final bool isEditing;
  final TextElement? activeText;
  final bool isNewText; // true = yeni oluşturuluyor, false = mevcut düzenleniyor
  final bool showMenu; // Menu gösteriliyor mu?
  final TextElement? menuText; // Hangi text için menu gösteriliyor?
  final bool showStylePopup; // Stil popup gösteriliyor mu?
  final TextElement? styleText; // Hangi text için stil düzenleniyor?
  final bool isMoving; // Taşıma modu aktif mi?
  final TextElement? movingText; // Hangi text taşınıyor?

  const TextToolState({
    this.isEditing = false,
    this.activeText,
    this.isNewText = true,
    this.showMenu = false,
    this.menuText,
    this.showStylePopup = false,
    this.styleText,
    this.isMoving = false,
    this.movingText,
  });

  TextToolState copyWith({
    bool? isEditing,
    TextElement? activeText,
    bool? isNewText,
    bool? showMenu,
    TextElement? menuText,
    bool? showStylePopup,
    TextElement? styleText,
    bool? isMoving,
    TextElement? movingText,
  }) {
    return TextToolState(
      isEditing: isEditing ?? this.isEditing,
      activeText: activeText ?? this.activeText,
      isNewText: isNewText ?? this.isNewText,
      showMenu: showMenu ?? this.showMenu,
      menuText: menuText ?? this.menuText,
      showStylePopup: showStylePopup ?? this.showStylePopup,
      styleText: styleText ?? this.styleText,
      isMoving: isMoving ?? this.isMoving,
      movingText: movingText ?? this.movingText,
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

  /// Text için context menu göster
  void showContextMenu(TextElement text) {
    state = TextToolState(
      showMenu: true,
      menuText: text,
    );
  }

  /// Context menu'yu kapat
  void hideContextMenu() {
    state = const TextToolState();
  }

  /// Stil popup'ı göster
  void showStylePopup(TextElement text) {
    state = TextToolState(
      showStylePopup: true,
      styleText: text,
    );
  }

  /// Stil popup'ı kapat
  void hideStylePopup() {
    state = const TextToolState();
  }

  /// Taşıma modunu başlat
  void startMoving(TextElement text) {
    state = TextToolState(
      isMoving: true,
      movingText: text,
    );
  }

  /// Taşıma modunu iptal et
  void cancelMoving() {
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
