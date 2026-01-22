/// Remote data source for sync operations using Supabase.
///
/// This data source handles all remote server operations for sync,
/// including pushing and pulling documents and folders.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:example_app/core/errors/exceptions.dart';

/// Remote data source for sync operations
class SyncRemoteDatasource {
  final SupabaseClient _client;

  /// Creates a sync remote data source
  const SyncRemoteDatasource(this._client);

  // ==================== Document Operations ====================

  /// Gets documents modified after a specific date
  Future<List<Map<String, dynamic>>> getDocumentsModifiedAfter(
    DateTime date,
  ) async {
    try {
      final response = await _client
          .from('documents')
          .select()
          .gt('updated_at', date.toIso8601String())
          .order('updated_at');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to get documents: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get documents: $e');
    }
  }

  /// Gets a single document by ID
  Future<Map<String, dynamic>?> getDocument(String id) async {
    try {
      final response =
          await _client.from('documents').select().eq('id', id).maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      throw ServerException('Failed to get document: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get document: $e');
    }
  }

  /// Creates or updates a document
  Future<void> upsertDocument(Map<String, dynamic> doc) async {
    try {
      await _client.from('documents').upsert(doc);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to upsert document: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to upsert document: $e');
    }
  }

  /// Deletes a document
  Future<void> deleteDocument(String id) async {
    try {
      await _client.from('documents').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to delete document: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to delete document: $e');
    }
  }

  /// Batch upsert multiple documents
  Future<void> batchUpsertDocuments(List<Map<String, dynamic>> docs) async {
    if (docs.isEmpty) return;

    try {
      await _client.from('documents').upsert(docs);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to batch upsert documents: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to batch upsert documents: $e');
    }
  }

  // ==================== Folder Operations ====================

  /// Gets folders modified after a specific date
  Future<List<Map<String, dynamic>>> getFoldersModifiedAfter(
    DateTime date,
  ) async {
    try {
      final response = await _client
          .from('folders')
          .select()
          .gt('created_at', date.toIso8601String())
          .order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to get folders: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get folders: $e');
    }
  }

  /// Gets a single folder by ID
  Future<Map<String, dynamic>?> getFolder(String id) async {
    try {
      final response =
          await _client.from('folders').select().eq('id', id).maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      throw ServerException('Failed to get folder: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get folder: $e');
    }
  }

  /// Creates or updates a folder
  Future<void> upsertFolder(Map<String, dynamic> folder) async {
    try {
      await _client.from('folders').upsert(folder);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to upsert folder: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to upsert folder: $e');
    }
  }

  /// Deletes a folder
  Future<void> deleteFolder(String id) async {
    try {
      await _client.from('folders').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to delete folder: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to delete folder: $e');
    }
  }

  /// Batch upsert multiple folders
  Future<void> batchUpsertFolders(List<Map<String, dynamic>> folders) async {
    if (folders.isEmpty) return;

    try {
      await _client.from('folders').upsert(folders);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to batch upsert folders: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to batch upsert folders: $e');
    }
  }

  // ==================== Sync Status Operations ====================

  /// Gets the last sync timestamp for the current user
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('sync_metadata')
          .select('last_sync_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      final lastSyncStr = response['last_sync_at'] as String?;
      return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
    } on PostgrestException catch (e) {
      throw ServerException('Failed to get last sync timestamp: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get last sync timestamp: $e');
    }
  }

  /// Updates the last sync timestamp for the current user
  Future<void> updateLastSyncTimestamp(DateTime timestamp) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException('No authenticated user');
      }

      await _client.from('sync_metadata').upsert({
        'user_id': userId,
        'last_sync_at': timestamp.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw ServerException('Failed to update last sync timestamp: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update last sync timestamp: $e');
    }
  }
}
