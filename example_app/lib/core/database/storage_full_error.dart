import 'dart:io';

import 'package:drift/drift.dart' show CouldNotRollBackException;
import 'package:drift/native.dart' show SqliteException;
// DriftRemoteException is how errors from the background database isolate
// arrive; only its type is used here.
// ignore: experimental_member_use
import 'package:drift/remote.dart' show DriftRemoteException;
import 'package:example_app/core/errors/exceptions.dart';
import 'package:example_app/core/errors/failures.dart';

/// SQLite primary result code SQLITE_FULL ("database or disk is full").
const _sqliteFull = 13;

/// SQLite's message for SQLITE_FULL.
const _sqliteFullMessage = 'database or disk is full';

/// POSIX errno ENOSPC ("No space left on device").
const _enospc = 28;

/// Whether [error] says the device has no space left: SQLite `SQLITE_FULL`
/// (also when Drift's background isolate wraps it in a
/// [DriftRemoteException], or inside a transaction Drift could not roll back),
/// a disk-full [FileSystemException], or an [AppException] caused by one of
/// these.
bool isStorageFull(Object? error) {
  for (var e = error, depth = 0; e != null && depth < 8; depth++) {
    if (e is SqliteException) return e.resultCode == _sqliteFull;
    // Same check as drawing_ui's isStorageFullError (not exported there).
    if (e is FileSystemException) {
      final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
      return e.osError?.errorCode == _enospc || text.contains('no space left');
    }
    // A serialized remote error keeps only SQLite's message text.
    if (e is String) return e.contains(_sqliteFullMessage);
    if (e is DriftRemoteException) {
      e = e.remoteCause;
    } else if (e is CouldNotRollBackException) {
      // SQLite already rolled the transaction back after SQLITE_FULL, so
      // Drift's own ROLLBACK fails and wraps the original error.
      e = e.cause;
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
