import 'package:drawing_core/src/internal.dart';

/// Birden fazla stroke'u tek seferde silme komutu.
///
/// Tek gesture = tek command (batching) prensibine uygun.
/// Bu, undo/redo history'sini temiz tutar.
class EraseStrokesCommand implements DrawingCommand {
  /// Silme işleminin yapılacağı layer indexi
  final int layerIndex;

  /// Silinecek stroke ID'leri
  final List<String> strokeIds;

  /// Undo için silinen stroke'ları cache'le
  final List<Stroke> _erasedStrokes = [];

  /// Cached elementOrder before execute (for undo z-order restore).
  List<String> _originalElementOrder = const [];

  /// Yeni bir [EraseStrokesCommand] oluşturur.
  ///
  /// [layerIndex] - Silme işleminin yapılacağı layer
  /// [strokeIds] - Silinecek stroke ID'lerinin listesi
  EraseStrokesCommand({
    required this.layerIndex,
    required this.strokeIds,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    final layer = document.layers[layerIndex];

    // Cache elementOrder before removal (for undo z-order restore)
    _originalElementOrder = List<String>.from(layer.elementOrder);

    // Silinecek stroke'ları cache'le (undo için)
    _erasedStrokes.clear();
    for (final id in strokeIds) {
      final stroke = layer.strokes.cast<Stroke?>().firstWhere(
            (s) => s?.id == id,
            orElse: () => null,
          );
      if (stroke != null) {
        _erasedStrokes.add(stroke);
      }
    }

    // Stroke'ları sil
    var updatedLayer = layer;
    for (final id in strokeIds) {
      updatedLayer = updatedLayer.removeStroke(id);
    }

    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (layerIndex < 0 || layerIndex >= document.layers.length) {
      return document;
    }

    var layer = document.layers[layerIndex];

    // Silinen stroke'ları geri ekle (ters sırada - orijinal pozisyonlara)
    for (final stroke in _erasedStrokes.reversed) {
      layer = layer.addStroke(stroke);
    }

    // Restore original elementOrder (addStroke appends to end, wrong z-order)
    if (_originalElementOrder.isNotEmpty) {
      layer = layer.copyWith(elementOrder: _originalElementOrder);
    }

    return document.updateLayer(layerIndex, layer);
  }

  @override
  String get description => 'Erase ${strokeIds.length} stroke(s)';
}
