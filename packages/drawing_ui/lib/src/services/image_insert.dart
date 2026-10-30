import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/services/image_import_storage.dart';
import 'package:drawing_ui/src/services/storage_errors.dart';

/// Why inserting a picked image failed.
enum ImageInsertError { pickerFailed, unreadable, storageFull, cannotWrite }

/// The outcome of [insertPickedImage]: exactly one of [storedPath] (the path
/// to persist on the element) and [error] is set.
class ImageInsertResult {
  const ImageInsertResult.stored(String this.storedPath) : error = null;
  const ImageInsertResult.failed(ImageInsertError this.error)
      : storedPath = null;

  final String? storedPath;
  final ImageInsertError? error;
}

/// Picks an image with [pick] (`null` = cancelled), checks that it decodes,
/// and copies it into the app images folder.
///
/// Never throws. A picker error, an undecodable file or a failed copy comes
/// back as [ImageInsertResult.error]; nothing is left on disk on failure.
/// Returns `null` when the user cancels.
Future<ImageInsertResult?> insertPickedImage(
  Future<String?> Function() pick, {
  required Future<String> Function() documentsRoot,
  PdfPathResolver paths = PdfPathResolver.passthrough,
}) async {
  final String? sourcePath;
  try {
    sourcePath = await pick();
  } catch (_) {
    return const ImageInsertResult.failed(ImageInsertError.pickerFailed);
  }
  if (sourcePath == null) return null;

  try {
    final bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      (await codec.getNextFrame()).image.dispose();
    } finally {
      codec.dispose();
    }
  } catch (_) {
    return const ImageInsertResult.failed(ImageInsertError.unreadable);
  }

  try {
    final stored = await storeImportedImage(
      sourcePath,
      documentsRoot: await documentsRoot(),
      paths: paths,
    );
    return ImageInsertResult.stored(stored);
  } on FileSystemException catch (e) {
    return ImageInsertResult.failed(isStorageFullError(e)
        ? ImageInsertError.storageFull
        : ImageInsertError.cannotWrite);
  } catch (_) {
    return const ImageInsertResult.failed(ImageInsertError.cannotWrite);
  }
}
