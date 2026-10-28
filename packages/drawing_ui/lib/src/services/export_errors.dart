import 'dart:io';

import 'storage_errors.dart';

/// Why an export failed. Widgets map it to copy through
/// `ExportFailureLabel.message`; services never carry user-facing text.
enum ExportFailure { storageFull, cannotWrite, failed, noPages }

/// Maps an export error to a typed failure that is safe to show to the user.
///
/// The raw error is never included; callers log it separately.
ExportFailure exportFailureFor(Object error) {
  if (error is FileSystemException) {
    return isStorageFullError(error)
        ? ExportFailure.storageFull
        : ExportFailure.cannotWrite;
  }
  return ExportFailure.failed;
}
