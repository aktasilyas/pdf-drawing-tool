import 'dart:io';

/// POSIX errno for "No space left on device".
const _enospc = 28;

/// Whether [error] reports that the device has no space left.
bool isStorageFullError(FileSystemException error) {
  final text = '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
  return error.osError?.errorCode == _enospc || text.contains('no space left');
}
