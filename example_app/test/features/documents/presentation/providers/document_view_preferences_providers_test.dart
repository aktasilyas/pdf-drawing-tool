import 'package:drawing_ui/drawing_ui.dart' show sharedPreferencesProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:example_app/core/constants/storage_keys.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/document_view_preferences_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  ProviderContainer containerFor(SharedPreferences? prefs) {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('stored choices are read synchronously on construction', () async {
    final prefs = await prefsWith({
      StorageKeys.viewMode: ViewMode.list.name,
      StorageKeys.sortOption: SortOption.name.name,
      StorageKeys.sortDirection: SortDirection.ascending.name,
      StorageKeys.pinFavoritesToTop: true,
    });
    final c = containerFor(prefs);

    expect(c.read(viewModeProvider), ViewMode.list);
    expect(c.read(sortOptionProvider), SortOption.name);
    expect(c.read(sortDirectionProvider), SortDirection.ascending);
    expect(c.read(pinFavoritesProvider), isTrue);
  });

  test('a change round-trips through a rebuilt container', () async {
    final prefs = await prefsWith({});
    final first = containerFor(prefs);
    await first.read(viewModeProvider.notifier).set(ViewMode.list);
    await first.read(sortOptionProvider.notifier).set(SortOption.size);
    await first
        .read(sortDirectionProvider.notifier)
        .set(SortDirection.ascending);
    await first.read(pinFavoritesProvider.notifier).toggle();

    final second = containerFor(prefs);
    expect(second.read(viewModeProvider), ViewMode.list);
    expect(second.read(sortOptionProvider), SortOption.size);
    expect(second.read(sortDirectionProvider), SortDirection.ascending);
    expect(second.read(pinFavoritesProvider), isTrue);
    // Same storage format as before: enum names and a bool.
    expect(prefs.getString(StorageKeys.viewMode), 'list');
    expect(prefs.getString(StorageKeys.sortOption), 'size');
    expect(prefs.getString(StorageKeys.sortDirection), 'ascending');
    expect(prefs.getBool(StorageKeys.pinFavoritesToTop), isTrue);
  });

  test('a change right after construction is kept', () async {
    final prefs = await prefsWith({StorageKeys.viewMode: ViewMode.grid.name});
    final c = containerFor(prefs);
    await c.read(viewModeProvider.notifier).set(ViewMode.list);
    // The old asynchronous initial load landed here and overwrote the change.
    await Future<void>.delayed(Duration.zero);

    expect(c.read(viewModeProvider), ViewMode.list);
  });

  test('unknown stored values fall back to the defaults', () async {
    final prefs = await prefsWith({
      StorageKeys.viewMode: 'carousel',
      StorageKeys.sortOption: 'colour',
      StorageKeys.sortDirection: 'sideways',
      StorageKeys.pinFavoritesToTop: 'yes',
    });
    final c = containerFor(prefs);

    expect(c.read(viewModeProvider), ViewMode.grid);
    expect(c.read(sortOptionProvider), SortOption.date);
    expect(c.read(sortDirectionProvider), SortDirection.descending);
    expect(c.read(pinFavoritesProvider), isFalse);
  });

  test('null prefs keep the choice in memory with the defaults', () async {
    final c = containerFor(null);
    expect(c.read(viewModeProvider), ViewMode.grid);
    expect(c.read(sortOptionProvider), SortOption.date);
    expect(c.read(sortDirectionProvider), SortDirection.descending);
    expect(c.read(pinFavoritesProvider), isFalse);

    await c.read(viewModeProvider.notifier).set(ViewMode.list);
    await c.read(pinFavoritesProvider.notifier).toggle();
    expect(c.read(viewModeProvider), ViewMode.list);
    expect(c.read(pinFavoritesProvider), isTrue);
  });
}
