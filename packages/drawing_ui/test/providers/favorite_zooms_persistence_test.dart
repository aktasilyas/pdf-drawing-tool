import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  ProviderContainer makeContainer(SharedPreferences? prefs) =>
      ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

  test('add, remove and toggle survive a rebuilt container', () async {
    final prefs = await prefsWith({});
    final first = makeContainer(prefs);
    final n = first.read(favoriteZoomsProvider.notifier);
    n.addFavorite(300);
    n.removeFavorite(150);
    n.toggleFavorite(50);
    n.toggleFavorite(200);
    first.dispose();

    final second = makeContainer(prefs);
    addTearDown(second.dispose);
    expect(second.read(favoriteZoomsProvider), [50, 100, 300]);
  });

  test('a change right after load is not overwritten', () async {
    final prefs = await prefsWith({
      'favorite_zooms': ['100', '250'],
    });
    final c = makeContainer(prefs);
    addTearDown(c.dispose);
    c.read(favoriteZoomsProvider.notifier).toggleFavorite(250);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(favoriteZoomsProvider), [100]);
  });

  test('corrupt, non-positive and duplicate entries are skipped', () async {
    final prefs = await prefsWith({
      'favorite_zooms': ['abc', '0', '-5', '200', '200', '100'],
    });
    final c = makeContainer(prefs);
    addTearDown(c.dispose);
    expect(c.read(favoriteZoomsProvider), [100, 200]);
  });

  test('empty or all-corrupt stored list loads defaults', () async {
    final prefs = await prefsWith({
      'favorite_zooms': ['x', '0'],
    });
    final c = makeContainer(prefs);
    addTearDown(c.dispose);
    expect(c.read(favoriteZoomsProvider), [100, 150, 200]);
  });

  test('null prefs works in memory with defaults', () {
    final c = makeContainer(null);
    addTearDown(c.dispose);
    expect(c.read(favoriteZoomsProvider), [100, 150, 200]);
    c.read(favoriteZoomsProvider.notifier).addFavorite(400);
    expect(c.read(favoriteZoomsProvider), [100, 150, 200, 400]);
  });
}
