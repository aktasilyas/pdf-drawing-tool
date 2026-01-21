import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  test('ColorPresets exposes default collections', () {
    expect(ColorPresets.quickAccess, isNotEmpty);
    expect(ColorPresets.classicLight.first, equals(const Color(0xFF000000)));
    expect(ColorSets.basic.length, equals(ColorPresets.classicLight.length));
    expect(ColorSets.all.containsKey('Temel'), isTrue);
  });
}
