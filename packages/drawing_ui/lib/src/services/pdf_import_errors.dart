import 'dart:io';

import 'pdf_loader.dart';

/// Maps an import failure to a message that is safe to show to the user.
String friendlyPdfImportError(Object error) {
  if (error is ArgumentError || error is StateError) {
    return error.toString();
  }
  final text = error is PDFLoaderException
      ? '${error.message} ${error.cause}'.toLowerCase()
      : error.toString().toLowerCase();
  if (text.contains('password') ||
      text.contains('encrypt') ||
      text.contains('parola')) {
    return 'Bu PDF parola korumalı. Parolayı kaldırıp tekrar deneyin.';
  }
  if (error is FileSystemException) {
    return 'PDF dosyasına erişilemedi.';
  }
  return 'PDF açılamadı. Dosya bozuk olabilir.';
}
