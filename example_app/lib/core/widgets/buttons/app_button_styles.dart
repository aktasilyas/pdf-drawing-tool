part of 'app_button.dart';

/// Per-variant [ButtonStyle] builders for [AppButton].
extension _AppButtonStyles on AppButton {
  /// Primary: Flat renk, shadow yok (default), press'te çok hafif elevation
  ButtonStyle _primaryStyle(_ButtonSpecs specs, AppPalette palette) =>
      ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        elevation: 0,
        shadowColor: palette.accent.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          return 0;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Color.lerp(palette.accent, palette.textPrimary, 0.15);
          }
          return palette.accent;
        }),
      );

  /// Secondary: surfaceVariant bg, textPrimary renk
  ButtonStyle _secondaryStyle(_ButtonSpecs specs, AppPalette palette) =>
      ElevatedButton.styleFrom(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          return 0;
        }),
      );

  /// Outline: 1px border, transparent bg, hover/press'te hafif fill
  ButtonStyle _outlineStyle(_ButtonSpecs specs, AppPalette palette) {
    final outlineColor = palette.border;
    final hoverFill = palette.surface;

    return OutlinedButton.styleFrom(
      foregroundColor: palette.accent,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      side: BorderSide(color: outlineColor),
      splashFactory: InkRipple.splashFactory,
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered)) {
          return hoverFill;
        }
        return Colors.transparent;
      }),
    );
  }

  /// Text: arka plan yok, border yok, sadece text + ripple
  ButtonStyle _textStyle(_ButtonSpecs specs, AppPalette palette) =>
      TextButton.styleFrom(
        foregroundColor: palette.accent,
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      );

  /// Destructive: flat error renk, beyaz text
  ButtonStyle _destructiveStyle(_ButtonSpecs specs, AppPalette palette) =>
      ElevatedButton.styleFrom(
        backgroundColor: palette.danger,
        foregroundColor: palette.onDanger,
        elevation: 0,
        shadowColor: palette.danger.withValues(alpha: 0.3),
        padding: EdgeInsets.symmetric(horizontal: specs.horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        splashFactory: InkRipple.splashFactory,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 1;
          return 0;
        }),
      );
}

/// Buton boyut spesifikasyonları.
class _ButtonSpecs {
  final double height;
  final double horizontalPadding;
  final double fontSize;
  final double iconSize;

  const _ButtonSpecs({
    required this.height,
    required this.horizontalPadding,
    required this.fontSize,
    required this.iconSize,
  });
}
