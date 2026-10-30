part of 'layer.dart';

/// Text, image and sticky-note operations for [Layer].
///
/// Kept in a mixin so `layer.dart` stays small; every method returns a
/// new [Layer].
mixin _LayerElementOps on _LayerStrokeOps {
  // ============================================================
  // TEXT METHODS
  // ============================================================

  /// Returns a new [Layer] with the given text element added.
  ///
  /// The original layer is not modified.
  Layer addText(TextElement text) {
    if (elementOrder.contains(text.id)) return this as Layer;
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: [...texts, text],
      images: images,
      stickyNotes: stickyNotes,
      elementOrder: [...elementOrder, text.id],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns a new [Layer] with the text matching [textId] removed.
  ///
  /// If no text with the given ID exists, returns a copy of this layer.
  /// The original layer is not modified.
  Layer removeText(String textId) {
    final newTexts = texts.where((t) => t.id != textId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: newTexts,
      images: images,
      stickyNotes: stickyNotes,
      elementOrder: elementOrder.where((id) => id != textId).toList(),
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns a new [Layer] with the text updated.
  ///
  /// The text is matched by ID. If no matching text is found,
  /// returns a copy of this layer unchanged.
  /// The original layer is not modified.
  Layer updateText(TextElement text) {
    final index = texts.indexWhere((t) => t.id == text.id);
    if (index == -1) {
      return copyWith();
    }

    final newTexts = List<TextElement>.from(texts);
    newTexts[index] = text;

    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: newTexts,
      images: images,
      stickyNotes: stickyNotes,
      elementOrder: elementOrder,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns the text element with the given [id], or null if not found.
  TextElement? getTextById(String textId) {
    for (final text in texts) {
      if (text.id == textId) {
        return text;
      }
    }
    return null;
  }

  // ============================================================
  // IMAGE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given image element added.
  Layer addImage(ImageElement image) {
    if (elementOrder.contains(image.id)) return this as Layer;
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: [...images, image],
      stickyNotes: stickyNotes,
      elementOrder: [...elementOrder, image.id],
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns a new [Layer] with the image matching [imageId] removed.
  Layer removeImage(String imageId) {
    final newImages = images.where((i) => i.id != imageId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: newImages,
      stickyNotes: stickyNotes,
      elementOrder: elementOrder.where((id) => id != imageId).toList(),
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns a new [Layer] with the image updated.
  Layer updateImage(ImageElement image) {
    final index = images.indexWhere((i) => i.id == image.id);
    if (index == -1) {
      return copyWith();
    }

    final newImages = List<ImageElement>.from(images);
    newImages[index] = image;

    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: newImages,
      stickyNotes: stickyNotes,
      elementOrder: elementOrder,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns the image element with the given [id], or null if not found.
  ImageElement? getImageById(String imageId) {
    for (final image in images) {
      if (image.id == imageId) {
        return image;
      }
    }
    return null;
  }

  // ============================================================
  // STICKY NOTE METHODS
  // ============================================================

  /// Returns a new [Layer] with the given sticky note added.
  Layer addStickyNote(StickyNote note) {
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: [...stickyNotes, note],
      elementOrder: elementOrder,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns a new [Layer] with the sticky note matching [noteId] removed.
  Layer removeStickyNote(String noteId) {
    final newNotes = stickyNotes.where((n) => n.id != noteId).toList();
    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: newNotes,
      elementOrder: elementOrder,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns a new [Layer] with the sticky note updated.
  Layer updateStickyNote(StickyNote note) {
    final index = stickyNotes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      return copyWith();
    }

    final newNotes = List<StickyNote>.from(stickyNotes);
    newNotes[index] = note;

    return Layer(
      id: id,
      name: name,
      strokes: strokes,
      shapes: shapes,
      texts: texts,
      images: images,
      stickyNotes: newNotes,
      elementOrder: elementOrder,
      isVisible: isVisible,
      isLocked: isLocked,
      opacity: opacity,
      unreadableElements: unreadableElements,
    );
  }

  /// Returns the sticky note with the given [id], or null if not found.
  StickyNote? getStickyNoteById(String noteId) {
    for (final note in stickyNotes) {
      if (note.id == noteId) {
        return note;
      }
    }
    return null;
  }
}
