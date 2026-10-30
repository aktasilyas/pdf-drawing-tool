/// ElyaNotes Design System - AppChip Component
///
/// Chip/tag komponenti.
///
/// Kullanım:
/// ```dart
/// AppChip(
///   label: 'Flutter',
///   icon: Icons.code,
///   onTap: () => select(),
/// )
///
/// AppChip(
///   label: 'Seçili',
///   isSelected: true,
///   onDelete: () => remove(),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/app_icon_button.dart';
import 'package:example_app/l10n/l10n.dart';

/// ElyaNotes chip komponenti.
///
/// Seçilebilir, silinebilir tag/chip. The visible pill is compact, but the
/// tap area is at least 48dp tall; screen readers hear the label and the
/// selected state, and the delete "x" is its own labelled 48dp button.
class AppChip extends StatelessWidget {
  /// Chip label'ı.
  final String label;

  /// Sol taraftaki icon (opsiyonel).
  final IconData? icon;

  /// Chip rengi (null ise tema rengi).
  final Color? color;

  /// Seçili durumu.
  final bool isSelected;

  /// Tıklama callback'i.
  final VoidCallback? onTap;

  /// Silme callback'i (varsa X butonu gösterilir).
  final VoidCallback? onDelete;

  const AppChip({
    required this.label,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final effectiveColor = color ?? palette.accent;
    final contentColor = isSelected ? palette.onAccent : palette.textPrimary;
    final pill = BorderRadius.circular(AppRadius.full);
    final hasDelete = onDelete != null;

    // The pill is drawn [AppSpacing.chipHeight] tall, centred in a band of
    // [AppSpacing.minTouchTarget] that takes the taps.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                height: AppSpacing.chipHeight,
                decoration: BoxDecoration(
                  color: isSelected ? effectiveColor : palette.surface,
                  borderRadius: pill,
                ),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mainArea(contentColor, pill, hasDelete),
                if (hasDelete) _deleteButton(context, contentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainArea(Color contentColor, BorderRadius pill, bool hasDelete) {
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: pill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: hasDelete ? 0 : AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.sm, color: contentColor),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteButton(BuildContext context, Color contentColor) {
    return AppIconButton(
      icon: Icons.close,
      tooltip: context.l10n.commonRemoveItem(label),
      onPressed: onDelete,
      variant: AppIconButtonVariant.ghost,
      size: AppIconButtonSize.small,
      iconColor: contentColor,
    );
  }
}
