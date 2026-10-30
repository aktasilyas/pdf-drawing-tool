import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'elyanotes_scroll_direction';
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  Axis setAndReload(Axis axis) {
    final first = makeContainer();
    first.read(scrollDirectionProvider.notifier).state = axis;
    return makeContainer().read(scrollDirectionProvider);
  }

  test('vertical survives a provider container rebuild', () {
    expect(setAndReload(Axis.vertical), Axis.vertical);
    expect(prefs.getString(key), 'vertical');
  });

  test('switching back to horizontal survives a rebuild', () {
    setAndReload(Axis.vertical);
    expect(setAndReload(Axis.horizontal), Axis.horizontal);
    expect(prefs.getString(key), 'horizontal');
  });

  test('missing value loads horizontal', () {
    expect(makeContainer().read(scrollDirectionProvider), Axis.horizontal);
  });

  test('unknown value loads horizontal without throwing', () async {
    SharedPreferences.setMockInitialValues({key: 'diagonal'});
    prefs = await SharedPreferences.getInstance();
    expect(makeContainer().read(scrollDirectionProvider), Axis.horizontal);
  });

  test('without prefs it stays in memory and defaults to horizontal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(scrollDirectionProvider), Axis.horizontal);
    container.read(scrollDirectionProvider.notifier).state = Axis.vertical;
    expect(container.read(scrollDirectionProvider), Axis.vertical);
  });
}
