import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Pure grid geometry for the library: column count, gaps and tile size.
///
/// Phones always get 2 columns; tablets fit as many 144dp-minimum tiles as
/// the pane allows (3..7). The tile is a 3:4 cover box plus an info block
/// whose height follows the text scale.
@immutable
class LibraryGridMetrics {
  const LibraryGridMetrics._({
    required this.columns,
    required this.crossGap,
    required this.rowGap,
    required this.tileWidth,
    required this.infoHeight,
  });

  factory LibraryGridMetrics.resolve({
    required double availableWidth,
    required bool isPhone,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final double crossGap = isPhone ? AppSpacing.lg : AppSpacing.xl;
    const double rowGap = AppSpacing.xl;
    final double fit = (availableWidth + crossGap) / (minTileWidth + crossGap);
    final int fitted = fit.floor().clamp(minColumns, maxColumns);
    final int columns = isPhone ? 2 : fitted;
    final double gaps = (columns - 1) * crossGap;
    final double tileWidth = (availableWidth - gaps) / columns;
    return LibraryGridMetrics._(
      columns: columns,
      crossGap: crossGap,
      rowGap: rowGap,
      tileWidth: tileWidth,
      infoHeight: infoBlockHeight(textScaler),
    );
  }

  /// Smallest tile width a tablet column may take.
  static const double minTileWidth = 144;
  static const int minColumns = 3;
  static const int maxColumns = 7;

  final int columns;
  final double crossGap;
  final double rowGap;
  final double tileWidth;

  /// Height of the title + meta block under the cover.
  final double infoHeight;

  /// Cover box height (3:4 portrait).
  double get coverHeight => tileWidth * 4 / 3;

  double get mainAxisExtent => coverHeight + infoHeight;

  SliverGridDelegateWithFixedCrossAxisCount get delegate =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossGap,
        mainAxisSpacing: rowGap,
        mainAxisExtent: mainAxisExtent,
      );

  /// Horizontal padding of the library pane.
  static double paneHorizontalPadding(bool isPhone) {
    if (isPhone) return AppSpacing.screenPaddingMobile;
    return AppSpacing.screenPaddingTablet;
  }

  /// `sm` gap + title line (16 x 1.5) + `xxs` + meta line (12 x 1.33),
  /// both font sizes passed through [s].
  static double infoBlockHeight(TextScaler s) {
    final double title = s.scale(16) * 1.5;
    final double meta = s.scale(12) * 1.33;
    final double total = AppSpacing.sm + title + AppSpacing.xxs + meta;
    return total.ceilToDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is LibraryGridMetrics &&
      other.columns == columns &&
      other.crossGap == crossGap &&
      other.rowGap == rowGap &&
      other.tileWidth == tileWidth &&
      other.infoHeight == infoHeight;

  @override
  int get hashCode {
    return Object.hash(columns, crossGap, rowGap, tileWidth, infoHeight);
  }
}
