import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/providers.dart';

/// Patterns offered by the infinite-canvas background panel.
enum InfiniteBackgroundPattern { plain, dotted, grid }

/// Colours offered by the infinite-canvas background panel (ARGB).
abstract final class InfiniteBackgroundColors {
  static const white = 0xFFFFFFFF;
  static const yellow = 0xFFFFF8E1;
  static const black = 0xFF1E1E1E;

  /// Whether [argb] is dark enough to need light foreground content.
  static bool isDark(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return (r * 299 + g * 587 + b * 114) / 1000 < 80;
  }

  /// The chip colour [argb] belongs to: yellow, black (incl. any dark colour)
  /// or white.
  static int groupOf(int argb) {
    if (argb == yellow) return yellow;
    if (argb == black || isDark(argb)) return black;
    return white;
  }
}

/// Pure builders for the backgrounds the panel produces.
abstract final class InfiniteBackgroundBuilder {
  static const _dotSpacing = 20.0;
  static const _gridSpacing = 25.0;
  static const _lightLine = 0xFFCCCCCC;
  static const _darkLine = 0xFF444444;

  /// Which panel pattern [bg] currently shows.
  static InfiniteBackgroundPattern patternOf(PageBackground bg) {
    switch (bg.type) {
      case BackgroundType.dotted:
        return InfiniteBackgroundPattern.dotted;
      case BackgroundType.grid:
        return InfiniteBackgroundPattern.grid;
      case BackgroundType.template:
        switch (bg.templatePattern) {
          case TemplatePattern.mediumDots:
          case TemplatePattern.smallDots:
          case TemplatePattern.largeDots:
            return InfiniteBackgroundPattern.dotted;
          case TemplatePattern.smallGrid:
          case TemplatePattern.mediumGrid:
          case TemplatePattern.largeGrid:
            return InfiniteBackgroundPattern.grid;
          default:
            return InfiniteBackgroundPattern.plain;
        }
      default:
        return InfiniteBackgroundPattern.plain;
    }
  }

  /// [current] with [pattern] applied; the colour is kept.
  static PageBackground withPattern(
    PageBackground current,
    InfiniteBackgroundPattern pattern,
  ) {
    switch (pattern) {
      case InfiniteBackgroundPattern.plain:
        return PageBackground(
            type: BackgroundType.blank, color: current.color);
      case InfiniteBackgroundPattern.dotted:
        return PageBackground(
            type: BackgroundType.dotted,
            color: current.color,
            gridSpacing: _dotSpacing,
            lineColor: _lightLine);
      case InfiniteBackgroundPattern.grid:
        return PageBackground(
            type: BackgroundType.grid,
            color: current.color,
            gridSpacing: _gridSpacing,
            lineColor: _lightLine);
    }
  }

  /// [current] with [colorArgb] applied; the pattern and spacing are kept and
  /// the line colour is adapted to the new colour.
  static PageBackground withColor(PageBackground current, int colorArgb) {
    return PageBackground(
      type: current.type,
      color: colorArgb,
      gridSpacing: current.gridSpacing,
      lineSpacing: current.lineSpacing,
      lineColor:
          colorArgb == InfiniteBackgroundColors.black ? _darkLine : _lightLine,
      templatePattern: current.templatePattern,
      templateSpacingMm: current.templateSpacingMm,
      templateLineWidth: current.templateLineWidth,
    );
  }
}

/// What the panel's chips do to the current page.
class InfiniteBackgroundActions {
  /// Creates the actions bound to [_ref].
  InfiniteBackgroundActions(this._ref);

  final Ref _ref;

  /// Switches the current page to [pattern], keeping its colour.
  void applyPattern(InfiniteBackgroundPattern pattern) {
    final page = _ref.read(currentPageProvider);
    _apply(InfiniteBackgroundBuilder.withPattern(page.background, pattern));
  }

  /// Switches the current page to [colorArgb], keeping its pattern.
  void applyColor(int colorArgb) {
    final page = _ref.read(currentPageProvider);
    _apply(InfiniteBackgroundBuilder.withColor(page.background, colorArgb));
  }

  void _apply(PageBackground background) {
    final page = _ref.read(currentPageProvider);
    _ref
        .read(documentProvider.notifier)
        .updatePageBackground(page.id, background);
    _ref
        .read(pageManagerProvider.notifier)
        .updateCurrentPage(page.copyWith(background: background));
  }
}

/// Infinite background panel actions.
final infiniteBackgroundActionsProvider =
    Provider<InfiniteBackgroundActions>(InfiniteBackgroundActions.new);
