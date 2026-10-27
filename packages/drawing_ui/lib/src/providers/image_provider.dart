import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

/// State for placing a new image on the canvas.
///
/// Placed images are selected, moved, scaled and rotated through the
/// selection tool (`SelectionHandles`), not through this state.
class ImagePlacementState {
  /// Path to the selected image file for placement.
  final String? selectedImagePath;

  /// Whether the user is in placement mode (tap canvas to place).
  bool get isPlacing => selectedImagePath != null;

  const ImagePlacementState({this.selectedImagePath});
}

/// Notifier for image placement state.
class ImagePlacementNotifier extends StateNotifier<ImagePlacementState> {
  ImagePlacementNotifier() : super(const ImagePlacementState());

  /// Enter placement mode with the given image path.
  void selectImagePath(String path) {
    state = ImagePlacementState(selectedImagePath: path);
  }

  /// Called after the image has been placed on canvas.
  void placed() {
    state = const ImagePlacementState();
  }

  /// Cancel placement mode.
  void cancel() {
    state = const ImagePlacementState();
  }
}

/// Provider for image placement state.
final imagePlacementProvider =
    StateNotifierProvider<ImagePlacementNotifier, ImagePlacementState>(
  (ref) => ImagePlacementNotifier(),
);

/// Reactive list of images in the active layer.
final activeLayerImagesProvider = Provider<List<ImageElement>>((ref) {
  final document = ref.watch(documentProvider);
  if (document.layers.isEmpty) return [];
  return document.layers[document.activeLayerIndex].images;
});
