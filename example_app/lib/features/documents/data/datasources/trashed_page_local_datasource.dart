import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';

abstract class TrashedPageLocalDatasource {
  Future<List<TrashedPageModel>> getTrashedPages();
  Future<TrashedPageModel?> getTrashedPage(String id);
  Future<void> addTrashedPage(TrashedPageModel page);
  Future<void> removeTrashedPage(String id);
}

class TrashedPageLocalDatasourceImpl implements TrashedPageLocalDatasource {
  static const String _key = 'trashed_pages';
  final SharedPreferences _prefs;

  TrashedPageLocalDatasourceImpl(this._prefs);

  @override
  Future<List<TrashedPageModel>> getTrashedPages() async {
    try {
      final jsonString = _prefs.getString(_key);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((j) => TrashedPageModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get trashed pages: $e');
    }
  }

  @override
  Future<TrashedPageModel?> getTrashedPage(String id) async {
    final pages = await getTrashedPages();
    try {
      return pages.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addTrashedPage(TrashedPageModel page) async {
    try {
      final pages = await getTrashedPages();
      pages.add(page);
      await _save(pages);
    } catch (e) {
      throw CacheException('Failed to add trashed page: $e');
    }
  }

  @override
  Future<void> removeTrashedPage(String id) async {
    try {
      final pages = await getTrashedPages();
      pages.removeWhere((p) => p.id == id);
      await _save(pages);
    } catch (e) {
      throw CacheException('Failed to remove trashed page: $e');
    }
  }

  Future<void> _save(List<TrashedPageModel> pages) async {
    final jsonList = pages.map((p) => p.toJson()).toList();
    await _prefs.setString(_key, json.encode(jsonList));
  }
}
