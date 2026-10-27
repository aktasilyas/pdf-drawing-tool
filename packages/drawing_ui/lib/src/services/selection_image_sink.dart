import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/services/selection_capture_service.dart';

/// Where a captured selection image goes: the device gallery and the
/// clipboard. A seam so the save flow can be tested without platform
/// channels.
abstract class SelectionImageSink {
  /// Saves PNG [bytes] to the gallery; false on failure.
  Future<bool> saveToGallery(Uint8List bytes);

  /// Copies PNG [bytes] to the clipboard; false on failure.
  Future<bool> copyToClipboard(Uint8List bytes);
}

/// The real sink, backed by the gallery and clipboard plugins.
class PlatformSelectionImageSink implements SelectionImageSink {
  const PlatformSelectionImageSink();

  @override
  Future<bool> saveToGallery(Uint8List bytes) =>
      SelectionCaptureService.saveToGallery(bytes);

  @override
  Future<bool> copyToClipboard(Uint8List bytes) =>
      SelectionCaptureService.copyToClipboard(bytes);
}

/// The sink the selection actions use; tests override it.
final selectionImageSinkProvider = Provider<SelectionImageSink>(
  (ref) => const PlatformSelectionImageSink(),
);

/// Outcome of [saveSelectionImage].
enum SelectionImageSaveResult { savedAndCopied, saved, copied, failed }

/// Saves [bytes] to the gallery and also copies them to the clipboard, so a
/// failed gallery save still leaves the image on the clipboard.
Future<SelectionImageSaveResult> saveSelectionImage(
  SelectionImageSink sink,
  Uint8List bytes,
) async {
  final saved = await sink.saveToGallery(bytes);
  final copied = await sink.copyToClipboard(bytes);
  if (saved && copied) return SelectionImageSaveResult.savedAndCopied;
  if (saved) return SelectionImageSaveResult.saved;
  if (copied) return SelectionImageSaveResult.copied;
  return SelectionImageSaveResult.failed;
}
