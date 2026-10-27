part of 'document.dart';

/// V1 layer operations and active-layer stroke helpers for [DrawingDocument].
///
/// A `part` of `document.dart` so it can read the private storage fields.
mixin _DocumentLayerOps on _DocumentV2Ops {
  /// Returns a new [DrawingDocument] with the given layer added.
  ///
  /// The new layer is added at the top and becomes the active layer.
  DrawingDocument addLayer(Layer layer) {
    if (isMultiPage) {
      // V2: Add to current page
      final current = currentPage;
      if (current == null) return _self;

      final newLayers = [...current.layers, layer];
      final updatedPage = current.copyWith(layers: newLayers);

      final newPages = List<Page>.from(pages);
      newPages[currentPageIndex] = updatedPage;

      return DrawingDocument.multiPage(
        id: id,
        title: title,
        pages: newPages,
        currentPageIndex: currentPageIndex,
        activeLayerIndex: newLayers.length - 1,
        settings: settings,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        documentType: documentType,
        audioRecordings: audioRecordings,
      );
    } else {
      // V1: Legacy
      final newLayers = [...layers, layer];
      return DrawingDocument(
        id: id,
        title: title,
        layers: newLayers,
        activeLayerIndex: newLayers.length - 1,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] whose current-page layers are [layers],
  /// with [activeLayerIndex] set explicitly (clamped to the valid range).
  ///
  /// Hides the V1 / V2 branching for layer structure commands.
  DrawingDocument withLayers(
    List<Layer> layers, {
    required int activeLayerIndex,
  }) {
    final active = layers.isEmpty
        ? 0
        : activeLayerIndex.clamp(0, layers.length - 1).toInt();

    if (isMultiPage) {
      final current = currentPage;
      if (current == null) return _self;

      final newPages = List<Page>.from(pages);
      newPages[currentPageIndex] =
          current.copyWith(layers: List<Layer>.from(layers));

      // copyWith keeps every other document field.
      return _self.copyWith(
        pages: newPages,
        activeLayerIndex: active,
        updatedAt: DateTime.now(),
      );
    }
    return DrawingDocument(
      id: id,
      title: title,
      layers: List<Layer>.from(layers),
      activeLayerIndex: active,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      width: width,
      height: height,
      documentType: documentType,
    );
  }

  /// Returns a new [DrawingDocument] with the layer at [index] removed.
  ///
  /// If removing would leave no layers, returns unchanged.
  DrawingDocument removeLayer(int index) {
    if (index < 0 || index >= layers.length || layers.length <= 1) {
      return _self.copyWith(updatedAt: DateTime.now());
    }

    if (isMultiPage) {
      // V2: Remove from current page
      final current = currentPage;
      if (current == null) return copyWith(updatedAt: DateTime.now());

      final newLayers = List<Layer>.from(current.layers)..removeAt(index);
      final updatedPage = current.copyWith(layers: newLayers);

      // Adjust activeLayerIndex if needed
      int newActiveIndex = activeLayerIndex;
      if (activeLayerIndex >= newLayers.length) {
        newActiveIndex = newLayers.length - 1;
      } else if (activeLayerIndex > index) {
        newActiveIndex = activeLayerIndex - 1;
      }

      final newPages = List<Page>.from(pages);
      newPages[currentPageIndex] = updatedPage;

      return DrawingDocument.multiPage(
        id: id,
        title: title,
        pages: newPages,
        currentPageIndex: currentPageIndex,
        activeLayerIndex: newActiveIndex,
        settings: settings,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        documentType: documentType,
        audioRecordings: audioRecordings,
      );
    } else {
      // V1: Legacy
      final newLayers = List<Layer>.from(layers)..removeAt(index);

      // Adjust activeLayerIndex if needed
      int newActiveIndex = activeLayerIndex;
      if (activeLayerIndex >= newLayers.length) {
        newActiveIndex = newLayers.length - 1;
      } else if (activeLayerIndex > index) {
        newActiveIndex = activeLayerIndex - 1;
      }

      return DrawingDocument(
        id: id,
        title: title,
        layers: newLayers,
        activeLayerIndex: newActiveIndex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] with the layer at [index] updated.
  ///
  /// If index is invalid, returns unchanged.
  DrawingDocument updateLayer(int index, Layer layer) {
    if (index < 0 || index >= layers.length) {
      return _self.copyWith(updatedAt: DateTime.now());
    }

    if (isMultiPage) {
      // V2: Update in current page
      final current = currentPage;
      if (current == null) return copyWith(updatedAt: DateTime.now());

      final newLayers = List<Layer>.from(current.layers);
      newLayers[index] = layer;

      final updatedPage = current.copyWith(layers: newLayers);
      return _updatePageV2(currentPageIndex, updatedPage);
    } else {
      // V1: Legacy
      final newLayers = List<Layer>.from(layers);
      newLayers[index] = layer;

      return DrawingDocument(
        id: id,
        title: title,
        layers: newLayers,
        activeLayerIndex: activeLayerIndex,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] with the active layer changed.
  ///
  /// If index is invalid, returns unchanged.
  DrawingDocument setActiveLayer(int index) {
    if (index < 0 || index >= layers.length) {
      return _self;
    }

    if (isMultiPage) {
      return DrawingDocument.multiPage(
        id: id,
        title: title,
        pages: pages,
        currentPageIndex: currentPageIndex,
        activeLayerIndex: index,
        settings: settings,
        createdAt: createdAt,
        updatedAt: updatedAt,
        documentType: documentType,
        audioRecordings: audioRecordings,
      );
    } else {
      // V1: Legacy
      return DrawingDocument(
        id: id,
        title: title,
        layers: layers,
        activeLayerIndex: index,
        createdAt: createdAt,
        updatedAt: updatedAt,
        width: width,
        height: height,
        documentType: documentType,
      );
    }
  }

  /// Returns a new [DrawingDocument] with the stroke added to the active layer.
  ///
  /// If there's no valid active layer, returns unchanged.
  DrawingDocument addStrokeToActiveLayer(Stroke stroke) {
    final active = activeLayer;
    if (active == null) {
      return _self;
    }

    final updatedLayer = active.addStroke(stroke);
    return updateLayer(activeLayerIndex, updatedLayer);
  }

  /// Returns a new [DrawingDocument] with the stroke removed from the active layer.
  ///
  /// If there's no valid active layer, returns unchanged.
  DrawingDocument removeStrokeFromActiveLayer(String strokeId) {
    final active = activeLayer;
    if (active == null) {
      return _self;
    }

    final updatedLayer = active.removeStroke(strokeId);
    return updateLayer(activeLayerIndex, updatedLayer);
  }

  /// Returns a new [DrawingDocument] with the title updated.
  DrawingDocument updateTitle(String newTitle) {
    return copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );
  }
}
