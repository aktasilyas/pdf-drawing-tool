part of 'document.dart';

/// V2 page and audio-recording operations for [DrawingDocument].
///
/// A `part` of `document.dart` so it can read the private storage fields.
mixin _DocumentV2Ops on _DocumentViews {
  /// Add a new page (V2 only).
  DrawingDocument addPage(Page page) {
    if (!isMultiPage) {
      throw UnsupportedError(
          'addPage() is only supported for V2 multi-page documents');
    }

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: [...pages, page],
      currentPageIndex: currentPageIndex,
      activeLayerIndex: activeLayerIndex,
      settings: settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  /// Remove a page (V2 only).
  DrawingDocument removePage(int pageIndex) {
    if (!isMultiPage) {
      throw UnsupportedError(
          'removePage() is only supported for V2 multi-page documents');
    }

    if (pageIndex < 0 || pageIndex >= pages.length || pages.length <= 1) {
      return _self;
    }

    final newPages = List<Page>.from(pages)..removeAt(pageIndex);
    for (var i = 0; i < newPages.length; i++) {
      if (newPages[i].index != i) newPages[i] = newPages[i].copyWith(index: i);
    }

    // Adjust currentPageIndex if needed
    int newCurrentIndex = currentPageIndex;
    if (currentPageIndex >= newPages.length) {
      newCurrentIndex = newPages.length - 1;
    } else if (currentPageIndex > pageIndex) {
      newCurrentIndex = currentPageIndex - 1;
    }

    // The active layer belongs to the old current page; reset it when the
    // current page identity changes (the current page itself was removed).
    final sameCurrent =
        newPages[newCurrentIndex].id == pages[currentPageIndex].id;

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: newPages,
      currentPageIndex: newCurrentIndex,
      activeLayerIndex: sameCurrent ? activeLayerIndex : 0,
      settings: settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  /// Set the current page (V2 only).
  ///
  /// Resets activeLayerIndex to 0 when switching pages.
  DrawingDocument setCurrentPage(int pageIndex) {
    if (!isMultiPage) {
      throw UnsupportedError(
          'setCurrentPage() is only supported for V2 multi-page documents');
    }

    if (pageIndex < 0 || pageIndex >= pages.length) {
      return _self;
    }

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: pages,
      currentPageIndex: pageIndex,
      activeLayerIndex: 0,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  /// Helper: Update a page in V2 document.
  DrawingDocument _updatePageV2(int pageIndex, Page updatedPage) {
    if (pageIndex < 0 || pageIndex >= pages.length) {
      return _self;
    }

    final newPages = List<Page>.from(pages);
    newPages[pageIndex] = updatedPage;

    return DrawingDocument.multiPage(
      id: id,
      title: title,
      pages: newPages,
      currentPageIndex: currentPageIndex,
      activeLayerIndex: activeLayerIndex,
      settings: settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      documentType: documentType,
      audioRecordings: audioRecordings,
    );
  }

  // ========== AUDIO RECORDING OPERATIONS ==========

  /// Add an audio recording to this document.
  DrawingDocument addAudioRecording(AudioRecording recording) {
    return copyWith(
      audioRecordings: [...audioRecordings, recording],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove an audio recording by ID.
  DrawingDocument removeAudioRecording(String recordingId) {
    return copyWith(
      audioRecordings:
          audioRecordings.where((r) => r.id != recordingId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Update an audio recording by ID.
  DrawingDocument updateAudioRecording(
      String recordingId, AudioRecording updated) {
    return copyWith(
      audioRecordings: audioRecordings
          .map((r) => r.id == recordingId ? updated : r)
          .toList(),
      updatedAt: DateTime.now(),
    );
  }
}
