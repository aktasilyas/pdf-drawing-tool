import 'dart:io';

/// POSIX errno for "No space left on device".
const _enospc = 28;

/// Why an export failed. Widgets map it to copy through
/// `ExportFailureLabel.message`; services never carry user-facing text.
enum ExportFailure { storageFull, cannotWrite, failed, noPages }

/// Shown when an export fails because the device storage is full.
const exportStorageFullMessage =
    'Dışa aktarma için yeterli depolama alanı yok. Yer açıp tekrar deneyin.';

/// Shown when an export cannot write its output file.
const exportCannotWriteMessage = 'Dosya yazılamadı. Tekrar deneyin.';

/// Shown for any other export failure.
const exportFailedMessage = 'Dışa aktarılamadı. Tekrar deneyin.';

/// Maps an export failure to a message that is safe to show to the user.
///
/// The raw error is never included; callers log it separately.
String friendlyExportError(Object error) {
  if (error is FileSystemException) {
    final code = error.osError?.errorCode;
    final text =
        '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
    if (code == _enospc || text.contains('no space left')) {
      return exportStorageFullMessage;
    }
    return exportCannotWriteMessage;
  }
  return exportFailedMessage;
}
