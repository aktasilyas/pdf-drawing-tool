/// Settings → Hakkında: version, privacy policy, licences, contact.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/settings/domain/entities/app_about_info.dart';
import 'package:example_app/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:example_app/l10n/l10n.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({
    super.key,
    this.buildName = appBuildName,
    this.buildNumber = appBuildNumber,
  });

  /// Injected for tests; defaults to the values `flutter build` embeds.
  final String? buildName;
  final String? buildNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final version = AppAboutInfo.formatVersion(buildName, buildNumber);
    final palette = context.palette;
    final muted = AppTypography.bodyMedium.copyWith(color: palette.textMuted);
    return SettingsSection(
      title: l10n.settingsSectionAbout,
      children: [
        const _AppIdentity(),
        SettingsTile(
          icon: Icons.info_outline,
          title: l10n.settingsVersion,
          showArrow: false,
          trailing: Text(version ?? '—', style: muted),
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.settingsPrivacyPolicy,
          onTap: () => _openPrivacyPolicy(context),
        ),
        SettingsTile(
          icon: Icons.description_outlined,
          title: l10n.settingsLicenses,
          onTap: () => _openLicenses(context, version),
        ),
        SettingsTile(
          icon: Icons.mail_outline,
          title: l10n.settingsFeedback,
          subtitle: AppAboutInfo.contactEmail,
          trailing: Icon(
            Icons.copy_outlined,
            size: AppIconSize.sm,
            color: palette.textMuted,
            semanticLabel: l10n.settingsCopy,
          ),
          onTap: () => _copyContactEmail(context),
        ),
      ],
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    final route = MaterialPageRoute<void>(
      builder: (_) => const PrivacyPolicyScreen(),
    );
    Navigator.of(context).push(route);
  }

  void _openLicenses(BuildContext context, String? version) {
    showLicensePage(
      context: context,
      applicationName: AppAboutInfo.appName,
      applicationVersion: version,
    );
  }

  Future<void> _copyContactEmail(BuildContext context) async {
    const data = ClipboardData(text: AppAboutInfo.contactEmail);
    await Clipboard.setData(data);
    if (context.mounted) {
      AppToast.success(context, context.l10n.settingsEmailCopied);
    }
  }
}

/// App icon and name at the top of the About card. The launcher icon has
/// its own light tile, so it reads on both themes (the wide wordmark PNG has
/// an opaque white background and showed as a white box in dark mode).
class _AppIdentity extends StatelessWidget {
  const _AppIdentity();

  static const double _iconSize = 64;

  @override
  Widget build(BuildContext context) {
    final nameStyle = AppTypography.titleLarge.copyWith(
      color: context.palette.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Image.asset(
              'assets/images/elyanotes_app_icon.png',
              width: _iconSize,
              height: _iconSize,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(AppAboutInfo.appName, style: nameStyle),
        ],
      ),
    );
  }
}
