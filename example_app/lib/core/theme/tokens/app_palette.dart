/// Elyanotes warm-paper palette (docs/design/BRIEF.md) as a ThemeExtension.
///
/// Widgets read roles via `context.palette` and never branch on brightness.
library;

import 'package:flutter/material.dart';

/// Semantic color roles, one instance per brightness.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentContainer,
    required this.danger,
    required this.onAccent,
    required this.onDanger,
    required this.paper,
  });

  /// Behind pages.
  final Color background;

  /// Panels and toolbars.
  final Color surface;
  final Color surfaceElevated;

  /// Hairline borders.
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  /// Ink blue: selection, focus, primary actions only.
  final Color accent;
  final Color accentContainer;
  final Color danger;

  /// Foreground on filled [accent] surfaces.
  final Color onAccent;

  /// Foreground on filled [danger] surfaces.
  final Color onDanger;

  /// Default page color; stays light in dark mode.
  final Color paper;

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F1EA),
    surface: Color(0xFFFBF9F4),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0xFFE4DED2),
    textPrimary: Color(0xFF22201C),
    textMuted: Color(0xFF6E685E),
    accent: Color(0xFF2B4C7E),
    accentContainer: Color(0xFFDCE5F2),
    danger: Color(0xFFB3261E),
    onAccent: Color(0xFFFFFFFF),
    onDanger: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFDF8),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF1B1A18),
    surface: Color(0xFF242320),
    surfaceElevated: Color(0xFF2D2B28),
    border: Color(0xFF3A3834),
    textPrimary: Color(0xFFECE8E0),
    textMuted: Color(0xFFA39D92),
    accent: Color(0xFF8FAEDB),
    accentContainer: Color(0xFF263548),
    danger: Color(0xFFF2B8B5),
    onAccent: Color(0xFF14233A),
    onDanger: Color(0xFF601410),
    paper: Color(0xFFF3EFE6),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? accent,
    Color? accentContainer,
    Color? danger,
    Color? onAccent,
    Color? onDanger,
    Color? paper,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      danger: danger ?? this.danger,
      onAccent: onAccent ?? this.onAccent,
      onDanger: onDanger ?? this.onDanger,
      paper: paper ?? this.paper,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette registered on the current [Theme].
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
