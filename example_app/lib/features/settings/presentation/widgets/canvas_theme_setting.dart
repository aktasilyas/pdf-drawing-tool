/// Canvas theme setting tile with segmented button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Canvas theme setting with SegmentedButton for Açık/Koyu/Sistem.
class CanvasThemeSetting extends ConsumerWidget {
  const CanvasThemeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(canvasDarkModeProvider);
    final palette = context.palette;
    final textColor = palette.textPrimary;
    final iconColor = palette.accent;
    final iconBgColor = palette.accentContainer;

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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.palette_outlined,
                    size: AppIconSize.sm, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.settingsCanvasTheme,
                  style: AppTypography.titleMedium.copyWith(color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<CanvasDarkMode>(
              segments: [
                ButtonSegment(
                  value: CanvasDarkMode.off,
                  label: Text(l10n.settingsThemeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: CanvasDarkMode.on,
                  label: Text(l10n.settingsThemeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: CanvasDarkMode.followSystem,
                  label: Text(l10n.settingsThemeSystem),
                  icon: const Icon(Icons.settings_suggest_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                ref
                    .read(canvasDarkModeProvider.notifier)
                    .setMode(selection.first);
              },
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(
                  Size(0, AppSpacing.minTouchTarget),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
