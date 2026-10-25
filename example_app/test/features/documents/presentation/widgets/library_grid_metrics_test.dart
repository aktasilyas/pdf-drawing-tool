import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/presentation/widgets/library_grid_metrics.dart';

LibraryGridMetrics _tablet(double w, {TextScaler? scaler}) =>
    LibraryGridMetrics.resolve(
      availableWidth: w,
      isPhone: false,
      textScaler: scaler ?? TextScaler.noScaling,
    );

void main() {
  group('LibraryGridMetrics.resolve', () {
    test('tablet landscape with sidebar: 5 columns', () {
      final m = _tablet(852);
      expect(m.columns, 5);
      expect(m.tileWidth, closeTo(151.2, 0.01));
      expect(m.crossGap, 24);
      expect(m.rowGap, 24);
    });

    test('tablet portrait, sidebar collapsed: 4 columns', () {
      final m = _tablet(772);
      expect(m.columns, 4);
      expect(m.tileWidth, closeTo(175, 0.01));
    });

    test('narrow tablet pane: 3 columns', () {
      final m = _tablet(492);
      expect(m.columns, 3);
      expect(m.tileWidth, closeTo(148, 0.01));
    });

    test('columns clamp to 3 and 7', () {
      expect(_tablet(300).columns, 3);
      expect(_tablet(2000).columns, 7);
    });

    test('phone: 2 columns, 16/24 gaps', () {
      final m = LibraryGridMetrics.resolve(
        availableWidth: 358,
        isPhone: true,
      );
      expect(m.columns, 2);
      expect(m.tileWidth, closeTo(171, 0.01));
      expect(m.crossGap, 16);
      expect(m.rowGap, 24);
    });
  });

  group('info block and extents', () {
    test('info height is 50 at 1.0 and 62 at 1.3', () {
      expect(_tablet(852).infoHeight, 50);
      expect(_tablet(852, scaler: const TextScaler.linear(1.3)).infoHeight, 62);
    });

    test('mainAxisExtent = 4w/3 + info', () {
      final m = _tablet(852);
      expect(m.coverHeight, closeTo(201.6, 0.01));
      expect(m.mainAxisExtent, closeTo(251.6, 0.01));
    });

    test('delegate mirrors the metrics', () {
      final m = _tablet(852);
      final d = m.delegate;
      expect(d.crossAxisCount, 5);
      expect(d.crossAxisSpacing, 24);
      expect(d.mainAxisSpacing, 24);
      expect(d.mainAxisExtent, closeTo(251.6, 0.01));
    });

    test('pane padding: 16 phone, 24 tablet', () {
      expect(LibraryGridMetrics.paneHorizontalPadding(true), 16);
      expect(LibraryGridMetrics.paneHorizontalPadding(false), 24);
    });
  });
}
