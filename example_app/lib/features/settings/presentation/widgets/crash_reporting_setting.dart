import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/settings/presentation/providers/crash_reporting_provider.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:example_app/l10n/l10n.dart';

/// Switch that lets the user opt out of anonymous crash reports.
class CrashReportingSetting extends ConsumerWidget {
  const CrashReportingSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(crashReportingEnabledProvider);
    return SettingsTile(
      icon: Icons.bug_report_outlined,
      title: l10n.settingsCrashReports,
      subtitle: l10n.settingsCrashReportsSubtitle,
      showArrow: false,
      trailing: Switch(
        value: enabled,
        activeTrackColor: context.palette.accent,
        onChanged: (v) =>
            ref.read(crashReportingEnabledProvider.notifier).set(v),
      ),
    );
  }
}
