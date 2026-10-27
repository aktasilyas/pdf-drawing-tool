import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

// =============================================================================
// DOCUMENT PROVIDER
// =============================================================================

/// Document state provider - centralized state for DrawingDocument.
///
/// This replaces the local _committedStrokes list in DrawingCanvas.
/// All stroke additions/removals go through this provider.
final documentProvider =
    StateNotifierProvider<DocumentNotifier, DrawingDocument>((ref) {
  return DocumentNotifier();
});

/// Active layer strokes - convenience provider.
///
/// Returns strokes from the currently active layer.
/// Use this in DrawingCanvas for rendering committed strokes.
final activeLayerStrokesProvider = Provider<List<Stroke>>((ref) {
  final document = ref.watch(documentProvider);
  return document.activeLayer?.strokes ?? [];
});

/// Total stroke count across all layers.
final strokeCountProvider = Provider<int>((ref) {
  final document = ref.watch(documentProvider);
  return document.strokeCount;
});

/// Is document empty (no strokes).
final isDocumentEmptyProvider = Provider<bool>((ref) {
  final document = ref.watch(documentProvider);
  return document.isEmpty;
});

/// Layer count in the document.
final layerCountProvider = Provider<int>((ref) {
  final document = ref.watch(documentProvider);
  return document.layerCount;
});

/// Active layer index.
final activeLayerIndexProvider = Provider<int>((ref) {
  final document = ref.watch(documentProvider);
  return document.activeLayerIndex;
});

/// All layers in the current page — for multi-layer rendering and layer panel.
final allLayersProvider = Provider<List<Layer>>((ref) {
  final document = ref.watch(documentProvider);
  return document.layers;
});

// =============================================================================
// DOCUMENT NOTIFIER
// =============================================================================

/// State notifier for DrawingDocument.
///
/// Manages document state including:
/// - Adding/removing strokes
/// - Layer management
/// - Document lifecycle (new, clear)
class DocumentNotifier extends StateNotifier<DrawingDocument> {
  /// Creates a new DocumentNotifier with an empty document.
  DocumentNotifier() : super(DrawingDocument.emptyMultiPage('İsimsiz Not'));

  /// Add stroke to active layer.
  ///
  /// This is called when a stroke is completed (pointer up).
  void addStroke(Stroke stroke) {
    state = state.addStrokeToActiveLayer(stroke);
  }

  /// Remove stroke from active layer by ID.
  ///
  /// Used by eraser tool.
  void removeStroke(String strokeId) {
    state = state.removeStrokeFromActiveLayer(strokeId);
  }

  /// Update entire document.
  ///
  /// Used for undo/redo operations.
  void updateDocument(DrawingDocument document) {
    state = document;
  }

  /// Clear active layer - removes all strokes.
  void clearActiveLayer() {
    final activeLayer = state.activeLayer;
    if (activeLayer != null) {
      state = state.updateLayer(
        state.activeLayerIndex,
        activeLayer.clear(),
      );
    }
  }

  /// Set active layer index.
  void setActiveLayer(int index) {
    if (index >= 0 && index < state.layerCount) {
      state = state.setActiveLayer(index);
    }
  }

  /// Rename a layer.
  void renameLayer(int index, String name) {
    final layers = state.layers;
    if (index < 0 || index >= layers.length) return;
    final updated = layers[index].copyWith(name: name);
    state = state.updateLayer(index, updated);
  }

  /// Toggle layer visibility.
  void toggleLayerVisibility(int index) {
    final layers = state.layers;
    if (index < 0 || index >= layers.length) return;
    final layer = layers[index];
    state =
        state.updateLayer(index, layer.copyWith(isVisible: !layer.isVisible));
  }

  /// Toggle layer locked state.
  void toggleLayerLocked(int index) {
    final layers = state.layers;
    if (index < 0 || index >= layers.length) return;
    final layer = layers[index];
    state = state.updateLayer(index, layer.copyWith(isLocked: !layer.isLocked));
  }

  /// Set layer opacity.
  void setLayerOpacity(int index, double opacity) {
    final layers = state.layers;
    if (index < 0 || index >= layers.length) return;
    state = state.updateLayer(index, layers[index].copyWith(opacity: opacity));
  }

  /// Create new document.
  ///
  /// Resets everything to a fresh state.
  void newDocument({String title = 'İsimsiz Not'}) {
    state = DrawingDocument.emptyMultiPage(title);
  }

  /// Update document title.
  void updateTitle(String title) {
    state = state.updateTitle(title);
  }

  /// Update page background (used for lazy loading PDF pages).
  void updatePageBackground(String pageId, PageBackground background) {
    final pages = state.pages;
    final pageIndex = pages.indexWhere((p) => p.id == pageId);

    if (pageIndex == -1) {
      debugPrint('WARNING: Page not found: $pageId');
      return;
    }

    final updatedPage = pages[pageIndex].copyWith(background: background);
    final updatedPages = List<Page>.from(pages);
    updatedPages[pageIndex] = updatedPage;

    state = state.copyWith(pages: updatedPages);
  }

  /// Get current document state.
  ///
  /// Useful for saving or undo/redo snapshots.
  DrawingDocument get currentDocument => state;
}
