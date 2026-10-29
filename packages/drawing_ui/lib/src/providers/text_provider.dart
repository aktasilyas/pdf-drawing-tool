import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

export 'package:drawing_ui/src/providers/text_settings_provider.dart';

/// Text tool state
class TextToolState {
  final bool isEditing;
  final TextElement? activeText;
  final bool
      isNewText; // true = yeni oluşturuluyor, false = mevcut düzenleniyor
  final bool showMenu; // Menu gösteriliyor mu?
  final TextElement? menuText; // Hangi text için menu gösteriliyor?
  final bool showStylePopup; // Stil popup gösteriliyor mu?
  final TextElement? styleText; // Hangi text için stil düzenleniyor?
  final bool isMoving; // Taşıma modu aktif mi?
  final TextElement? movingText; // Hangi text taşınıyor?

  /// Id of the page the edited text belongs to, captured when editing
  /// starts; null means "the current page" (#462).
  final String? originPageId;

  /// Layer index on [originPageId], captured when editing starts.
  final int? originLayerIndex;

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
    this.originPageId,
    this.originLayerIndex,
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
      originPageId: originPageId,
      originLayerIndex: originLayerIndex,
    );
  }
}

/// Text tool notifier
class TextToolNotifier extends StateNotifier<TextToolState> {
  TextToolNotifier() : super(const TextToolState());

  /// Starts a new text at ([x], [y]) on page [pageId], layer [layerIndex].
  void startNewText(
    double x,
    double y, {
    String? pageId,
    int? layerIndex,
    double fontSize = 16.0,
    int color = 0xFF000000,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
  }) {
    final text = TextElement.create(
      text: '',
      x: x,
      y: y,
      fontSize: fontSize,
      color: color,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
    );

    state = TextToolState(
      isEditing: true,
      activeText: text,
      isNewText: true,
      originPageId: pageId,
      originLayerIndex: layerIndex,
    );
  }

  /// Starts editing [text], which lives on page [pageId], layer [layerIndex].
  void editExistingText(TextElement text, {String? pageId, int? layerIndex}) {
    state = TextToolState(
      isEditing: true,
      activeText: text,
      isNewText: false,
      originPageId: pageId,
      originLayerIndex: layerIndex,
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
