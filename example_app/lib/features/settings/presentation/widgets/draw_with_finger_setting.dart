import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:example_app/l10n/l10n.dart';

/// Lets fingers draw even after a stylus has been detected.
class DrawWithFingerSetting extends ConsumerWidget {
  const DrawWithFingerSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fingerDraws = ref.watch(inputModeProvider).fingerDraws;
    return SettingsTile(
      icon: Icons.touch_app_outlined,
      title: l10n.settingsDrawWithFinger,
      subtitle: l10n.settingsDrawWithFingerSubtitle,
      showArrow: false,
      trailing: Switch(
        value: fingerDraws,
        activeTrackColor: context.palette.accent,
        onChanged: (v) =>
            ref.read(inputModeProvider.notifier).setDrawWithFinger(v),
      ),
    );
  }
}
