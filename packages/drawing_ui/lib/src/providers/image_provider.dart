import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

/// State for image placement, selection, and context menu.
class ImagePlacementState {
  /// Path to the selected image file for placement.
  final String? selectedImagePath;

  /// Whether the user is in placement mode (tap canvas to place).
  bool get isPlacing => selectedImagePath != null;

  /// Currently selected image element (for resize handles + context menu).
  final ImageElement? selectedImage;

  /// Whether the context menu is visible for the selected image.
  final bool showMenu;

  /// Image element being moved.
  final ImageElement? movingImage;

  /// Whether move mode is active.
  bool get isMoving => movingImage != null;

  const ImagePlacementState({
    this.selectedImagePath,
    this.selectedImage,
    this.showMenu = false,
    this.movingImage,
  });
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

  /// Select an image element (shows handles + context menu).
  void selectImage(ImageElement image) {
    state = ImagePlacementState(selectedImage: image, showMenu: true);
  }

  /// Hide context menu but keep image selected (handles remain).
  void hideContextMenu() {
    state = ImagePlacementState(selectedImage: state.selectedImage);
  }

  /// Deselect image entirely (clears handles + menu).
  void deselectImage() {
    state = const ImagePlacementState();
  }

  /// Update the selected image (e.g. after resize).
  void updateSelectedImage(ImageElement image) {
    state = ImagePlacementState(selectedImage: image);
  }

  /// Start moving the given image.
  void startMoving(ImageElement image) {
    state = ImagePlacementState(movingImage: image);
  }

  /// Cancel moving.
  void cancelMoving() {
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
