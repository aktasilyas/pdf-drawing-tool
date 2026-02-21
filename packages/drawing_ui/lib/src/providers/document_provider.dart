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

  /// Add new layer.
  void addLayer(String name) {
    final newLayer = Layer.empty(name);
    state = state.addLayer(newLayer);
  }

  /// Remove layer by index.
  ///
  /// Cannot remove if only one layer exists.
  void removeLayer(int index) {
    if (state.layerCount > 1) {
      state = state.removeLayer(index);
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
    state = state.updateLayer(index, layer.copyWith(isVisible: !layer.isVisible));
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

  /// Reorder layers: remove from [oldIndex], insert at [newIndex].
  ///
  /// Uses remove-then-insert semantics — [newIndex] is the position
  /// in the list AFTER the item has been removed.
  void reorderLayers(int oldIndex, int newIndex) {
    final layers = List<Layer>.from(state.layers);
    if (oldIndex < 0 || oldIndex >= layers.length) return;
    if (newIndex < 0 || newIndex >= layers.length) return;
    if (oldIndex == newIndex) return;

    final layer = layers.removeAt(oldIndex);
    layers.insert(newIndex, layer);

    final current = state.currentPage;
    if (current == null) return;
    final updatedPage = current.copyWith(layers: layers);
    final newPages = List<Page>.from(state.pages);
    newPages[state.currentPageIndex] = updatedPage;

    // Track where the active layer ended up
    int newActiveIndex = state.activeLayerIndex;
    if (state.activeLayerIndex == oldIndex) {
      newActiveIndex = newIndex;
    } else {
      // After removal, indices above oldIndex shift down by 1
      if (state.activeLayerIndex > oldIndex) newActiveIndex--;
      // After insertion, indices at/above newIndex shift up by 1
      if (newActiveIndex >= newIndex) newActiveIndex++;
    }

    state = state.copyWith(
      pages: newPages,
      activeLayerIndex: newActiveIndex,
      updatedAt: DateTime.now(),
    );
  }

  /// Duplicate a layer.
  void duplicateLayer(int index) {
    final layers = state.layers;
    if (index < 0 || index >= layers.length) return;

    final source = layers[index];
    final duplicate = source.copyWith(
      id: 'layer_${DateTime.now().microsecondsSinceEpoch}',
      name: _duplicateName(source.name),
    );

    // Insert duplicate above the source layer
    final newLayers = List<Layer>.from(layers);
    newLayers.insert(index + 1, duplicate);

    final current = state.currentPage;
    if (current == null) return;
    final updatedPage = current.copyWith(layers: newLayers);
    final newPages = List<Page>.from(state.pages);
    newPages[state.currentPageIndex] = updatedPage;

    // Set the duplicate as the active layer
    state = state.copyWith(
      pages: newPages,
      activeLayerIndex: index + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a smart duplicate name: "Foo" → "Foo (2)", "Foo (2)" → "Foo (3)".
  static String _duplicateName(String original) {
    final match = RegExp(r'^(.+?)\s*\((\d+)\)$').firstMatch(original);
    if (match != null) {
      final base = match.group(1)!;
      final num = int.parse(match.group(2)!) + 1;
      return '$base ($num)';
    }
    return '$original (2)';
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
