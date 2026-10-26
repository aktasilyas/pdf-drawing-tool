// Private variant widgets of AppIconButton (filled, tonal, outline, ghost).
// Split out of app_icon_button.dart to keep both files under the 300-line
// limit; a part keeps them private to the component.
part of 'app_icon_button.dart';

// ══════════════════════════════════════════════════════════════════════════
// VARIANT WIDGETS
// ══════════════════════════════════════════════════════════════════════════

class _FilledIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Widget child;

  const _FilledIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.accent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: SizedBox(
          width: size,
          height: size,
          child: IconTheme(
            data: IconThemeData(color: palette.onAccent),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _TonalIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Widget child;

  const _TonalIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected ? AppColors.primaryLight : AppColors.surfaceVariantLight,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: SizedBox(
          width: size,
          height: size,
          child: IconTheme(
            data: IconThemeData(
              color: isSelected ? AppColors.onPrimary : AppColors.primary,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _OutlineIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Widget child;

  const _OutlineIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: AppColors.primary,
              width: isSelected ? 0 : 1,
            ),
          ),
          child: IconTheme(
            data: IconThemeData(
              color: isSelected ? AppColors.onPrimary : AppColors.primary,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;
  final Color? iconColor;
  final Widget child;

  const _GhostIconButton({
    required this.onPressed,
    required this.size,
    required this.isSelected,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isSelected
        ? palette.accent
        : (onPressed == null
            ? palette.textDisabled
            : iconColor ?? palette.textMuted);

    return Material(
      color: isSelected ? palette.accentContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        splashFactory: NoSplash.splashFactory,
        highlightColor: palette.textPrimary.withValues(alpha: 0.06),
        child: SizedBox(
          width: size,
          height: size,
          child: IconTheme(
            data: IconThemeData(color: color),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
