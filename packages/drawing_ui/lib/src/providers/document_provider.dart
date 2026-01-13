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
  DocumentNotifier() : super(DrawingDocument.empty('İsimsiz Not'));

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

  /// Create new document.
  ///
  /// Resets everything to a fresh state.
  void newDocument({String title = 'İsimsiz Not'}) {
    state = DrawingDocument.empty(title);
  }

  /// Update document title.
  void updateTitle(String title) {
    state = state.updateTitle(title);
  }

  /// Get current document state.
  ///
  /// Useful for saving or undo/redo snapshots.
  DrawingDocument get currentDocument => state;
}
