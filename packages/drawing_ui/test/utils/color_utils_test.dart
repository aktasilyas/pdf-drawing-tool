import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    test('withAlphaSafe creates color with correct alpha', () {
      final red = Colors.red;
      final transparentRed = red.withAlphaSafe(0.5);

      expect(transparentRed.alphaInt, 128); // 0.5 * 255 ≈ 128
    });

    test('withAlphaSafe clamps values', () {
      final red = Colors.red;
      
      final fullyTransparent = red.withAlphaSafe(0.0);
      expect(fullyTransparent.alphaInt, 0);

      final fullyOpaque = red.withAlphaSafe(1.0);
      expect(fullyOpaque.alphaInt, 255);
    });

    test('matchesRGB ignores alpha', () {
      final red1 = Colors.red.withAlpha(128);
      final red2 = Colors.red.withAlpha(255);

      expect(red1.matchesRGB(red2), true);
      expect(red2.matchesRGB(red1), true);
    });

    test('matchesRGB detects different colors', () {
      final red = Colors.red;
      final blue = Colors.blue;

      expect(red.matchesRGB(blue), false);
    });

    test('rgbInt returns correct integer values', () {
      final color = const Color(0xFFFF8040); // R=255, G=128, B=64
      final rgb = color.rgbInt;

      expect(rgb.r, 255);
      expect(rgb.g, 128);
      expect(rgb.b, 64);
    });

    test('alphaInt returns correct integer value', () {
      final color = const Color(0x80FF0000); // A=128, R=255
      expect(color.alphaInt, 128);

      final opaqueColor = const Color(0xFFFF0000); // A=255
      expect(opaqueColor.alphaInt, 255);
    });
  });
}
