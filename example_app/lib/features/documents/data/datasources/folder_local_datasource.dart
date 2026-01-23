import 'dart:async';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/folder_model.dart';

abstract class FolderLocalDatasource {
  Future<List<FolderModel>> getFolders({String? parentId});
  Future<FolderModel> getFolder(String id);
  Future<FolderModel> createFolder(FolderModel folder);
  Future<FolderModel> updateFolder(FolderModel folder);
  Future<void> deleteFolder(String id);
  Stream<List<FolderModel>> watchFolders({String? parentId});
}

@Injectable(as: FolderLocalDatasource)
class FolderLocalDatasourceImpl implements FolderLocalDatasource {
  static const String _foldersKey = 'folders';
  final SharedPreferences _prefs;
  final StreamController<List<FolderModel>> _controller =
      StreamController<List<FolderModel>>.broadcast();

  FolderLocalDatasourceImpl(this._prefs);

  @override
  Future<List<FolderModel>> getFolders({String? parentId}) async {
    try {
      final jsonString = _prefs.getString(_foldersKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString) as List;
      final folders = jsonList
          .map((json) => FolderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (parentId == null) {
        return folders;
      }

      return folders.where((folder) => folder.parentId == parentId).toList();
    } catch (e) {
      throw CacheException('Failed to get folders: $e');
    }
  }

  @override
  Future<FolderModel> getFolder(String id) async {
    try {
      final folders = await getFolders();
      return folders.firstWhere(
        (folder) => folder.id == id,
        orElse: () => throw CacheException('Folder not found'),
      );
    } catch (e) {
      throw CacheException('Failed to get folder: $e');
    }
  }

  @override
  Future<FolderModel> createFolder(FolderModel folder) async {
    try {
      final folders = await getFolders();
      folders.add(folder);
      await _saveFolders(folders);
      _controller.add(folders);
      return folder;
    } catch (e) {
      throw CacheException('Failed to create folder: $e');
    }
  }

  @override
  Future<FolderModel> updateFolder(FolderModel folder) async {
    try {
      final folders = await getFolders();
      final index = folders.indexWhere((f) => f.id == folder.id);
      
      if (index == -1) {
        throw CacheException('Folder not found');
      }

      folders[index] = folder;
      await _saveFolders(folders);
      _controller.add(folders);
      return folder;
    } catch (e) {
      throw CacheException('Failed to update folder: $e');
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    try {
      final folders = await getFolders();
      folders.removeWhere((folder) => folder.id == id);
      await _saveFolders(folders);
      _controller.add(folders);
    } catch (e) {
      throw CacheException('Failed to delete folder: $e');
    }
  }

  @override
  Stream<List<FolderModel>> watchFolders({String? parentId}) {
    // Emit initial data
    getFolders(parentId: parentId).then((folders) {
      if (!_controller.isClosed) {
        _controller.add(folders);
      }
    });

    if (parentId == null) {
      return _controller.stream;
    }

    return _controller.stream.map(
      (folders) => folders.where((f) => f.parentId == parentId).toList(),
    );
  }

  Future<void> _saveFolders(List<FolderModel> folders) async {
    try {
      final jsonList = folders.map((folder) => folder.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _prefs.setString(_foldersKey, jsonString);
    } catch (e) {
      throw CacheException('Failed to save folders: $e');
    }
  }

  void dispose() {
    _controller.close();
  }
}
