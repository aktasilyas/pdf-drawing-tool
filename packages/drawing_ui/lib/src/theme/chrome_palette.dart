/// Editor chrome colour roles (docs/specs/52-editor-chrome.md, D1).
///
/// The host app registers a [ChromePalette] on its [ThemeData.extensions]
/// (example_app builds it from `AppPalette`). Widgets read
/// [ChromePalette.of] and never branch on brightness. The const [light] and
/// [dark] defaults are the brief's table; they are the only place in
/// drawing_ui where chrome colour literals are allowed.
library;

import 'package:flutter/material.dart';

/// Semantic colour roles for toolbars, panels and the page sidebar.
@immutable
class ChromePalette extends ThemeExtension<ChromePalette> {
  const ChromePalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.textDisabled,
    required this.accent,
    required this.accentContainer,
    required this.onAccent,
    required this.danger,
    required this.paper,
  });

  /// Maps a plain [ColorScheme] when the host registers no palette.
  factory ChromePalette.fromColorScheme(ColorScheme s) => ChromePalette(
        background: s.surfaceContainerLow,
        surface: s.surface,
        surfaceElevated: s.surfaceBright,
        border: s.outlineVariant,
        textPrimary: s.onSurface,
        textMuted: s.onSurfaceVariant,
        textDisabled: s.onSurface.withValues(alpha: 0.38),
        accent: s.primary,
        accentContainer: s.primaryContainer,
        onAccent: s.onPrimary,
        danger: s.error,
        paper: light.paper,
      );

  /// The registered palette, or one derived from the theme's colour scheme.
  static ChromePalette of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ChromePalette>() ??
        ChromePalette.fromColorScheme(theme.colorScheme);
  }

  /// Desk band behind the page and the toolbar capsules.
  final Color background;

  /// Toolbar capsules and the docked sidebar card.
  final Color surface;

  /// Popovers, sheets and other short-lived panels.
  final Color surfaceElevated;

  /// Hairline borders.
  final Color border;
  final Color textPrimary;

  /// Idle icons and secondary labels.
  final Color textMuted;
  final Color textDisabled;

  /// Ink blue: selection, focus and primary actions only.
  final Color accent;

  /// Fill behind a selected control.
  final Color accentContainer;

  /// Foreground on filled [accent] surfaces.
  final Color onAccent;
  final Color danger;

  /// Default page colour; stays light in dark mode.
  final Color paper;

  static const ChromePalette light = ChromePalette(
    background: Color(0xFFF4F1EA),
    surface: Color(0xFFFBF9F4),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0xFFE4DED2),
    textPrimary: Color(0xFF22201C),
    textMuted: Color(0xFF6E685E),
    textDisabled: Color(0xFFA8A296),
    accent: Color(0xFF2B4C7E),
    accentContainer: Color(0xFFDCE5F2),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB3261E),
    paper: Color(0xFFFFFDF8),
  );

  static const ChromePalette dark = ChromePalette(
    background: Color(0xFF1B1A18),
    surface: Color(0xFF242320),
    surfaceElevated: Color(0xFF2D2B28),
    border: Color(0xFF3A3834),
    textPrimary: Color(0xFFECE8E0),
    textMuted: Color(0xFFA39D92),
    textDisabled: Color(0xFF6B665E),
    accent: Color(0xFF8FAEDB),
    accentContainer: Color(0xFF263548),
    onAccent: Color(0xFF14233A),
    danger: Color(0xFFF2B8B5),
    paper: Color(0xFFF3EFE6),
  );

  List<Color> get _roles => [
        background,
        surface,
        surfaceElevated,
        border,
        textPrimary,
        textMuted,
        textDisabled,
        accent,
        accentContainer,
        onAccent,
        danger,
        paper,
      ];

  @override
  ChromePalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? textDisabled,
    Color? accent,
    Color? accentContainer,
    Color? onAccent,
    Color? danger,
    Color? paper,
  }) {
    return ChromePalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      paper: paper ?? this.paper,
    );
  }

  @override
  ChromePalette lerp(ThemeExtension<ChromePalette>? other, double t) {
    if (other is! ChromePalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return ChromePalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      border: mix(border, other.border),
      textPrimary: mix(textPrimary, other.textPrimary),
      textMuted: mix(textMuted, other.textMuted),
      textDisabled: mix(textDisabled, other.textDisabled),
      accent: mix(accent, other.accent),
      accentContainer: mix(accentContainer, other.accentContainer),
      onAccent: mix(onAccent, other.onAccent),
      danger: mix(danger, other.danger),
      paper: mix(paper, other.paper),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChromePalette) return false;
    final a = _roles;
    final b = other._roles;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_roles);
}
