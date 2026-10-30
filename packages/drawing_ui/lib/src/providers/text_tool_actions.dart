import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_provider.dart';
import 'history_provider.dart';
import 'page_provider.dart';
import 'text_provider.dart';

/// Ends text-tool editing and records the result in the undo history.
///
/// The text being typed lives only in [textToolProvider] until it is
/// committed. The canvas commits on tap, scale, page change and focus loss;
/// the app calls [commit] before it saves on Back, Home or app background, so
/// typed text is never lost (#489).
class TextToolActions {
  TextToolActions(this._ref);

  final Ref _ref;

  /// Commits the text being edited to the page and layer it was started on
  /// (#462), even when the current page changed in the meantime.
  ///
  /// A new text is added with one [AddTextCommand], an edited one updated
  /// with one [UpdateTextCommand]. Empty or whitespace-only content goes
  /// through [endEmptied]. Does nothing when no text is being edited.
  ///
  /// Returns the added text when a new text was created, else null.
  TextElement? commit() {
    final state = _ref.read(textToolProvider);
    if (!state.isEditing) return null;
    final text = state.activeText;
    if (text == null || text.text.trim().isEmpty) {
      endEmptied();
      return null;
    }

    _ref.read(textToolProvider.notifier).finishEditing();
    final history = _ref.read(historyManagerProvider.notifier);
    final layerIndex = _originLayerIndex(state);
    if (state.isNewText) {
      history.execute(
        AddTextCommand(layerIndex: layerIndex, textElement: text),
        pageId: state.originPageId,
      );
      return text;
    }
    history.execute(
      UpdateTextCommand(layerIndex: layerIndex, newText: text),
      pageId: state.originPageId,
    );
    return null;
  }

  /// Ends editing whose content is empty or whitespace only.
  ///
  /// A new text creates nothing. An existing text is removed with one
  /// [RemoveTextCommand], so undo brings the original text back.
  void endEmptied() {
    final state = _ref.read(textToolProvider);
    final text = state.activeText;
    _ref.read(textToolProvider.notifier).cancelEditing();
    if (text == null || state.isNewText) return;

    final exists = _originLayerTexts(state).any((t) => t.id == text.id);
    if (!exists) return;
    _ref.read(historyManagerProvider.notifier).execute(
          RemoveTextCommand(
            layerIndex: _originLayerIndex(state),
            textId: text.id,
          ),
          pageId: state.originPageId,
        );
  }

  /// Whether the text being edited was started on the current page.
  bool isOnCurrentPage(TextToolState state) =>
      state.originPageId == null ||
      state.originPageId == _ref.read(currentPageProvider).id;

  int _originLayerIndex(TextToolState s) =>
      s.originLayerIndex ?? _ref.read(documentProvider).activeLayerIndex;

  /// Texts of the layer the edited text was started on.
  List<TextElement> _originLayerTexts(TextToolState s) {
    final document = _ref.read(documentProvider);
    final pageId = s.originPageId;
    if (pageId == null || !document.isMultiPage) {
      return _ref.read(activeLayerTextsProvider);
    }
    final index = document.pages.indexWhere((p) => p.id == pageId);
    if (index < 0) return const [];
    final layers = document.pages[index].layers;
    final layerIndex = _originLayerIndex(s);
    if (layerIndex < 0 || layerIndex >= layers.length) return const [];
    return layers[layerIndex].texts;
  }
}

/// The [TextToolActions] of the open document.
final textToolActionsProvider = Provider<TextToolActions>(TextToolActions.new);
