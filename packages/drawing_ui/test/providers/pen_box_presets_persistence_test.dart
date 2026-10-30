import 'dart:convert';

import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const presetsKey = 'elyanotes_pen_box_presets';
  const indexKey = 'elyanotes_pen_box_selected_index';
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

  const brush = PenPreset(
    id: 'brush',
    toolType: ToolType.brushPen,
    color: Color(0xFFE53935),
    thickness: 7.5,
    nibShape: NibShapeType.ellipse,
  );
  const pencil = PenPreset(
    id: 'pencil',
    toolType: ToolType.pencil,
    color: Color(0xFF1E88E5),
    thickness: 1.5,
    nibShape: NibShapeType.rectangle,
  );
  const ballpoint = PenPreset(id: 'ballpoint');

  test('add, update and remove survive a container rebuild in order', () {
    final first = makeContainer();
    first.read(penBoxPresetsProvider.notifier)
      ..addPreset(ballpoint)
      ..addPreset(brush)
      ..addPreset(pencil)
      ..updatePreset(1, brush.copyWith(thickness: 9.0))
      ..removePreset(0);
    first.dispose();

    final second = makeContainer();
    addTearDown(second.dispose);
    final presets = second.read(penBoxPresetsProvider);
    expect(presets.map((p) => p.id), ['brush', 'pencil']);
    expect(presets[0].toolType, ToolType.brushPen);
    expect(presets[0].color, const Color(0xFFE53935));
    expect(presets[0].thickness, 9.0);
    expect(presets[0].nibShape, NibShapeType.ellipse);
    expect(presets[1].toolType, ToolType.pencil);
    expect(presets[1].color, const Color(0xFF1E88E5));
    expect(presets[1].thickness, 1.5);
    expect(presets[1].nibShape, NibShapeType.rectangle);
    expect(presets[1].isEmpty, isFalse);
  });

  test('corrupt JSON loads an empty list without throwing', () {
    prefs.setString(presetsKey, '{not json');
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(penBoxPresetsProvider), isEmpty);
  });

  test('non-list JSON loads an empty list', () {
    prefs.setString(presetsKey, '{"id":"a"}');
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(penBoxPresetsProvider), isEmpty);
  });

  test('entries with an unknown tool or bad fields are skipped', () {
    final raw = jsonEncode([
      {'id': 'a', 'toolType': 'laserSword', 'color': 1, 'thickness': 2},
      {'id': 'b', 'toolType': 'pencil', 'color': 'red', 'thickness': 2},
      {'id': 'c', 'toolType': 'pencil', 'color': 1, 'thickness': -1},
      'not an object',
      {'id': 'd', 'toolType': 'pencil', 'color': 0xFF000000, 'thickness': 3},
    ]);
    prefs.setString(presetsKey, raw);
    final c = makeContainer();
    addTearDown(c.dispose);
    final presets = c.read(penBoxPresetsProvider);
    expect(presets.map((p) => p.id), ['d']);
    // Missing nib and isEmpty fall back to the defaults.
    expect(presets.single.nibShape, NibShapeType.circle);
    expect(presets.single.isEmpty, isFalse);
  });

  test('selected index survives a container rebuild', () {
    final first = makeContainer();
    first.read(penBoxPresetsProvider.notifier)
      ..addPreset(ballpoint)
      ..addPreset(brush)
      ..addPreset(pencil);
    first.read(selectedPresetIndexProvider.notifier).state = 2;
    first.dispose();

    final second = makeContainer();
    addTearDown(second.dispose);
    expect(second.read(selectedPresetIndexProvider), 2);
  });

  test('an out-of-range stored index is clamped to the list', () {
    final raw = jsonEncode([
      {'id': 'a', 'toolType': 'pencil', 'color': 1, 'thickness': 2},
      {'id': 'b', 'toolType': 'pencil', 'color': 1, 'thickness': 2},
    ]);
    prefs.setString(presetsKey, raw);
    prefs.setInt(indexKey, 7);
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(selectedPresetIndexProvider), 1);
  });

  test('a negative stored index or an empty list loads index 0', () {
    prefs.setInt(indexKey, -4);
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(selectedPresetIndexProvider), 0);
  });

  test('null prefs behave as in-memory', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(penBoxPresetsProvider.notifier).addPreset(brush);
    c.read(selectedPresetIndexProvider.notifier).state = 3;
    expect(c.read(penBoxPresetsProvider).single.id, 'brush');
    expect(c.read(selectedPresetIndexProvider), 3);
  });
}
