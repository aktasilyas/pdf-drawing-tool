import 'dart:convert';

import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'elyanotes_shapes';
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

  void expectDefaults(ShapesSettingsState s) {
    expect(s.selectedShape, ShapeType.rectangle);
    expect(s.strokeThickness, 2.0);
    expect(s.strokeColor, const Color(0xFF000000));
    expect(s.fillEnabled, isFalse);
    expect(s.fillColor, const Color(0x40000000));
  }

  test('all fields survive a provider container rebuild', () {
    final first = makeContainer();
    first.read(shapesSettingsProvider.notifier)
      ..setSelectedShape(ShapeType.star)
      ..setStrokeThickness(5.5)
      ..setStrokeColor(const Color(0xFF2196F3))
      ..setFillEnabled(true)
      ..setFillColor(const Color(0x80FF0000));
    first.dispose();

    final second = makeContainer();
    addTearDown(second.dispose);
    final s = second.read(shapesSettingsProvider);
    expect(s.selectedShape, ShapeType.star);
    expect(s.strokeThickness, 5.5);
    expect(s.strokeColor, const Color(0xFF2196F3));
    expect(s.fillEnabled, isTrue);
    expect(s.fillColor, const Color(0x80FF0000));
  });

  test('empty prefs load the defaults', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    expectDefaults(c.read(shapesSettingsProvider));
  });

  test('invalid JSON loads the defaults without throwing', () {
    prefs.setString(key, '{not json');
    final c = makeContainer();
    addTearDown(c.dispose);
    expectDefaults(c.read(shapesSettingsProvider));
  });

  test('non-object JSON loads the defaults without throwing', () {
    prefs.setString(key, '[1, 2, 3]');
    final c = makeContainer();
    addTearDown(c.dispose);
    expectDefaults(c.read(shapesSettingsProvider));
  });

  test('unknown or wrongly typed fields fall back per field', () {
    final raw = jsonEncode({
      'selectedShape': 'hexagram',
      'strokeThickness': 'thick',
      'strokeColor': 'red',
      'fillEnabled': 1,
      'fillColor': 0xFF0000FF,
    });
    prefs.setString(key, raw);
    final c = makeContainer();
    addTearDown(c.dispose);
    final s = c.read(shapesSettingsProvider);
    expect(s.selectedShape, ShapeType.rectangle);
    expect(s.strokeThickness, 2.0);
    expect(s.strokeColor, const Color(0xFF000000));
    expect(s.fillEnabled, isFalse);
    expect(s.fillColor, const Color(0xFF0000FF));
  });

  test('non-finite or non-positive thickness falls back to the default', () {
    prefs.setString(key, '{"strokeThickness":-3}');
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(shapesSettingsProvider).strokeThickness, 2.0);
  });

  test('null prefs behave as in-memory defaults', () {
    final notifier = ShapesSettingsNotifier(null);
    expectDefaults(notifier.state);
    notifier.setSelectedShape(ShapeType.arrow);
    expect(notifier.state.selectedShape, ShapeType.arrow);
  });
}
