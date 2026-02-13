/// Canvas theme setting tile with segmented button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';

/// Canvas theme setting with SegmentedButton for Açık/Koyu/Sistem.
class CanvasThemeSetting extends ConsumerWidget {
  const CanvasThemeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(canvasDarkModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final iconColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  size: AppIconSize.md, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Text('Canvas Teması',
                  style: AppTypography.titleMedium.copyWith(color: textColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<CanvasDarkMode>(
              segments: const [
                ButtonSegment(
                  value: CanvasDarkMode.off,
                  label: Text('Açık'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: CanvasDarkMode.on,
                  label: Text('Koyu'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: CanvasDarkMode.followSystem,
                  label: Text('Sistem'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                ref
                    .read(canvasDarkModeProvider.notifier)
                    .setMode(selection.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
