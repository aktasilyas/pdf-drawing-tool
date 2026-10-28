import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/popover_layout.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _screen = Size(800, 1000);
const _edge = ChromeSpacing.md;
const _gap = ChromeSpacing.sm;

PopoverLayout _layout(Rect anchor, {double maxWidth = 280}) =>
    PopoverLayout(anchor: anchor, screenSize: _screen, maxWidth: maxWidth);

void main() {
  test('opens below with an sm gap, centred on the anchor', () {
    final l = _layout(const Rect.fromLTWH(300, 100, 48, 48));
    expect(l.placement, PopoverPlacement.below);
    expect(l.top, 148 + _gap);
    expect(l.bottom, isNull);
    expect(l.left, 324 - 140);
    expect(l.maxHeight, 1000 - 148 - _gap - _edge);
    expect(l.scaleAlignment, Alignment.topCenter);
  });

  test('flips above when less than minSpace is free below', () {
    final l = _layout(const Rect.fromLTWH(300, 800, 48, 48));
    expect(l.placement, PopoverPlacement.above);
    expect(l.top, isNull);
    expect(l.bottom, 1000 - 800 + _gap);
    expect(l.maxHeight, 800 - _gap - _edge);
    expect(l.scaleAlignment, Alignment.bottomCenter);
  });

  test('opens to the right when neither vertical side has room', () {
    const screen = Size(800, 500);
    const l = PopoverLayout(
      anchor: Rect.fromLTWH(20, 220, 48, 48),
      screenSize: screen,
      maxWidth: 280,
    );
    expect(l.placement, PopoverPlacement.right);
    expect(l.left, 68 + _gap);
    expect(l.maxHeight, 500 - _edge * 2);
    expect(l.top, _edge);
    expect(l.scaleAlignment, Alignment.centerLeft);
  });

  test('clamps to the left screen edge', () {
    final l = _layout(const Rect.fromLTWH(0, 100, 48, 48));
    expect(l.left, _edge);
  });

  test('clamps to the right screen edge', () {
    final l = _layout(const Rect.fromLTWH(752, 100, 48, 48));
    expect(l.left, 800 - 280 - _edge);
  });
}
