/// ElyaNotes Design System - AppIconButton Component
///
/// Icon-only buton komponenti. 4 variant ve 3 size destekler.
///
/// Kullanım:
/// ```dart
/// AppIconButton(
///   icon: Icons.add,
///   onPressed: () => add(),
///   tooltip: 'Ekle',
///   variant: AppIconButtonVariant.filled,
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

part 'app_icon_button_variants.dart';

/// Icon buton varyantları.
enum AppIconButtonVariant {
  /// Dolu arka plan - Primary renk
  filled,

  /// Tonlu arka plan - Primary light renk
  tonal,

  /// Kenarlıklı - Transparent arka plan
  outline,

  /// Hayalet - Sadece icon
  ghost,
}

/// Icon buton boyutları.
enum AppIconButtonSize {
  /// Küçük: 40dp (48dp touch target)
  small,

  /// Orta: 44dp (varsayılan)
  medium,

  /// Büyük: 52dp
  large,
}

/// ElyaNotes icon buton komponenti.
///
/// 4 farklı variant ve 3 farklı boyut destekler.
/// Tooltip accessibility için önemlidir.
class AppIconButton extends StatelessWidget {
  /// Gösterilecek icon.
  final IconData icon;

  /// Butona tıklandığında çağrılacak fonksiyon.
  /// Null ise buton disabled görünür.
  final VoidCallback? onPressed;

  /// Accessibility için tooltip metni. Aynı zamanda semantics etiketi
  /// olarak kullanılır ([semanticLabel] verilmediyse).
  final String? tooltip;

  /// Screen-reader label when it must differ from [tooltip] (or when the
  /// button shows no tooltip). Falls back to [tooltip].
  final String? semanticLabel;

  /// Buton varyantı.
  final AppIconButtonVariant variant;

  /// Buton boyutu.
  final AppIconButtonSize size;

  /// Seçili durumu (toggle butonlar için).
  /// Affects the tonal, outline and ghost variants only; the filled variant
  /// ignores it.
  final bool isSelected;

  /// Icon color for the ghost variant when enabled and not selected.
  /// Defaults to `palette.textMuted`. Ignored by the other variants.
  final Color? iconColor;

  const AppIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.variant = AppIconButtonVariant.filled,
    this.size = AppIconButtonSize.medium,
    this.isSelected = false,
    this.iconColor,
    super.key,
  }) : assert(
          tooltip != null || semanticLabel != null,
          'An icon-only button needs a tooltip or a semanticLabel',
        );

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final specs = _getSpecs();

    Widget button = SizedBox(
      width: specs.touchTarget,
      height: specs.touchTarget,
      child: Center(
        child: _buildButton(specs, isDisabled),
      ),
    );

    // Ghost signals disabled with textDisabled instead of fading.
    if (isDisabled && variant != AppIconButtonVariant.ghost) {
      button = Opacity(opacity: 0.5, child: button);
    }

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    // One node for the whole button: the inner InkWell would otherwise be a
    // second, unlabelled button node next to the tooltip's label node, and
    // without `container` the label would be absorbed into a neighbour's node.
    return Semantics(
      container: true,
      button: true,
      enabled: !isDisabled,
      label: semanticLabel ?? tooltip,
      onTap: onPressed,
      excludeSemantics: true,
      child: button,
    );
  }

  Widget _buildButton(_IconButtonSpecs specs, bool isDisabled) {
    final iconWidget = Icon(icon, size: specs.iconSize);

    switch (variant) {
      case AppIconButtonVariant.filled:
        return _FilledIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          child: iconWidget,
        );

      case AppIconButtonVariant.tonal:
        return _TonalIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          child: iconWidget,
        );

      case AppIconButtonVariant.outline:
        return _OutlineIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          child: iconWidget,
        );

      case AppIconButtonVariant.ghost:
        return _GhostIconButton(
          onPressed: isDisabled ? null : onPressed,
          size: specs.buttonSize,
          isSelected: isSelected,
          iconColor: iconColor,
          child: iconWidget,
        );
    }
  }

  _IconButtonSpecs _getSpecs() {
    switch (size) {
      case AppIconButtonSize.small:
        return const _IconButtonSpecs(
          buttonSize: 40,
          touchTarget: AppSpacing.minTouchTarget,
          iconSize: AppIconSize.md,
        );
      case AppIconButtonSize.medium:
        return const _IconButtonSpecs(
          buttonSize: 44,
          touchTarget: AppSpacing.minTouchTarget,
          iconSize: AppIconSize.lg,
        );
      case AppIconButtonSize.large:
        return const _IconButtonSpecs(
          buttonSize: 52,
          touchTarget: 52,
          iconSize: AppIconSize.lg,
        );
    }
  }
}

/// Icon buton boyut spesifikasyonları.
class _IconButtonSpecs {
  final double buttonSize;
  final double touchTarget;
  final double iconSize;

  const _IconButtonSpecs({
    required this.buttonSize,
    required this.touchTarget,
    required this.iconSize,
  });
}
