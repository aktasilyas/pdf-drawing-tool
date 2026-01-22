/// Sync conflict entity representing a conflict between local and remote data.
///
/// A conflict occurs when the same entity has been modified both locally
/// and remotely since the last sync.
library;

import 'package:equatable/equatable.dart';

/// Types of conflict resolution strategies
enum ConflictResolution {
  /// Keep the local version
  keepLocal,

  /// Keep the remote version
  keepRemote,

  /// Keep both versions (create duplicate)
  keepBoth,
}

/// Represents a synchronization conflict
class SyncConflict extends Equatable {
  /// ID of the document in conflict
  final String documentId;

  /// Title of the document
  final String documentTitle;

  /// When the local version was last modified
  final DateTime localModified;

  /// When the remote version was last modified
  final DateTime remoteModified;

  /// Creates a sync conflict
  const SyncConflict({
    required this.documentId,
    required this.documentTitle,
    required this.localModified,
    required this.remoteModified,
  });

  /// Whether the local version is newer
  bool get isLocalNewer => localModified.isAfter(remoteModified);

  /// Whether the remote version is newer
  bool get isRemoteNewer => remoteModified.isAfter(localModified);

  /// Time difference in seconds between versions
  int get timeDifference {
    return localModified.difference(remoteModified).inSeconds.abs();
  }

  @override
  List<Object?> get props => [
        documentId,
        documentTitle,
        localModified,
        remoteModified,
      ];
}
