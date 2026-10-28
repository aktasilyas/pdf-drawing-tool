import 'dart:io';

/// POSIX errno for "No space left on device".
const _enospc = 28;

/// Why an export failed. Widgets map it to copy through
/// `ExportFailureLabel.message`; services never carry user-facing text.
enum ExportFailure { storageFull, cannotWrite, failed, noPages }

/// Maps an export error to a typed failure that is safe to show to the user.
///
/// The raw error is never included; callers log it separately.
ExportFailure exportFailureFor(Object error) {
  if (error is FileSystemException) {
    final code = error.osError?.errorCode;
    final text =
        '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
    if (code == _enospc || text.contains('no space left')) {
      return ExportFailure.storageFull;
    }
    return ExportFailure.cannotWrite;
  }
  return ExportFailure.failed;
}
