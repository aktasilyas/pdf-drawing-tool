import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';

import 'package:drawing_ui/src/services/image_import_storage.dart';

/// Why [importImagePage] failed.
enum ImagePageImportError { unreadable, tooLarge }

/// Thrown by [importImagePage]; nothing was written to disk.
class ImagePageImportException implements Exception {
  const ImagePageImportException(this.error);

  final ImagePageImportError error;

  @override
  String toString() => 'ImagePageImportException($error)';
}

/// A page background that references a stored image, and the page size that
/// matches the image's pixel dimensions.
typedef ImagePage = ({PageBackground background, PageSize size});

/// Validates the image at [sourcePath], copies it into the app images folder
/// and returns a background that references the stored file.
///
/// The image is decoded before anything is copied, so a failure leaves no
/// file behind. When [maxDimension] is set, an image whose width or height
/// exceeds it throws [ImagePageImportError.tooLarge]; any read or decode
/// failure throws [ImagePageImportError.unreadable].
Future<ImagePage> importImagePage(
  String sourcePath, {
  required String documentsRoot,
  PdfPathResolver paths = PdfPathResolver.passthrough,
  int? maxDimension,
}) async {
  final Uint8List bytes;
  final int width;
  final int height;
  try {
    bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      width = frame.image.width;
      height = frame.image.height;
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
  } catch (_) {
    throw const ImagePageImportException(ImagePageImportError.unreadable);
  }
  final limit = maxDimension;
  if (limit != null && (width > limit || height > limit)) {
    throw const ImagePageImportException(ImagePageImportError.tooLarge);
  }

  final String stored;
  try {
    stored = await storeImportedImage(
      sourcePath,
      documentsRoot: documentsRoot,
      paths: paths,
    );
  } catch (_) {
    throw const ImagePageImportException(ImagePageImportError.unreadable);
  }
  return (
    background: PageBackground(
      type: BackgroundType.pdf,
      pdfPageIndex: 1,
      imageFilePath: stored,
      pdfData: bytes,
    ),
    size: PageSize(width: width.toDouble(), height: height.toDouble()),
  );
}

/// Deletes the file [importImagePage] stored for [page] when the page is not
/// used after all (the editor closed, the document could not be created).
/// Best effort; never throws.
Future<void> discardImportedImagePage(
  ImagePage page, {
  PdfPathResolver paths = PdfPathResolver.passthrough,
}) async {
  final stored = page.background.imageFilePath;
  if (stored == null) return;
  try {
    final file = File(paths.resolve(stored));
    if (await file.exists()) await file.delete();
  } catch (_) {
    // A leftover file only costs disk space.
  }
}
