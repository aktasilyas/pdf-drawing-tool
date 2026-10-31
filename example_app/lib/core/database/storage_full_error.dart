import 'dart:io';

import 'package:drift/native.dart' show SqliteException;
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:example_app/core/errors/exceptions.dart';
import 'package:example_app/core/errors/failures.dart';

/// SQLite primary result code SQLITE_FULL ("database or disk is full").
const _sqliteFull = 13;

/// POSIX errno ENOSPC ("No space left on device").
const _enospc = 28;

/// Whether [error] says the device has no space left: SQLite `SQLITE_FULL`
/// (also when Drift's background isolate wraps it in a
/// [DriftRemoteException]), a disk-full [FileSystemException], or an
/// [AppException] caused by one of these.
bool isStorageFull(Object? error) {
  for (var e = error, depth = 0; e != null && depth < 8; depth++) {
    if (e is SqliteException) return e.resultCode == _sqliteFull;
    if (e is FileSystemException) {
      final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
      return e.osError?.errorCode == _enospc || text.contains('no space left');
    }
    if (e is DriftRemoteException) {
      e = e.remoteCause;
    } else if (e is AppException && e.originalError != null) {
      e = e.originalError;
    } else {
      return false;
    }
  }
  return false;
}

/// [StorageFullFailure] when [error] is a storage-full error, otherwise a
/// [CacheFailure] with [message].
CacheFailure cacheFailureFor(Object error, String message) =>
    isStorageFull(error) ? StorageFullFailure(message) : CacheFailure(message);
