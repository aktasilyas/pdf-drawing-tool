import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spacing follows the spec scale (4dp grid plus xxs)', () {
    expect(ChromeSpacing.xxs, 2);
    expect(ChromeSpacing.xs, 4);
    expect(ChromeSpacing.sm, 8);
    expect(ChromeSpacing.md, 12);
    expect(ChromeSpacing.lg, 16);
    expect(ChromeSpacing.xl, 24);
    expect(ChromeSpacing.xxl, 32);
  });

  test('radii', () {
    expect(ChromeRadius.sm, 8);
    expect(ChromeRadius.md, 10);
    expect(ChromeRadius.lg, 12);
    expect(ChromeRadius.xl, 16);
    expect(ChromeRadius.xxl, 20);
    expect(ChromeRadius.full, 999);
  });

  test('durations', () {
    expect(ChromeDurations.instant, const Duration(milliseconds: 100));
    expect(ChromeDurations.fast, const Duration(milliseconds: 200));
    expect(ChromeDurations.normal, const Duration(milliseconds: 300));
  });

  test('icon sizes', () {
    expect(ChromeIconSizes.sm, 16);
    expect(ChromeIconSizes.md, 20);
    expect(ChromeIconSizes.lg, 24);
  });

  test('touch target is at least 48dp', () {
    expect(ChromeSizes.minTouchTarget, greaterThanOrEqualTo(48));
  });
}
