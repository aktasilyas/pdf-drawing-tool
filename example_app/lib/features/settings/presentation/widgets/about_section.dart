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
    final version = AppAboutInfo.formatVersion(buildName, buildNumber);
    final palette = context.palette;
    final muted = AppTypography.bodyMedium.copyWith(color: palette.textMuted);
    return SettingsSection(
      title: 'HAKKINDA',
      children: [
        const _AppIdentity(),
        SettingsTile(
          icon: Icons.info_outline,
          title: 'Sürüm',
          showArrow: false,
          trailing: Text(version ?? '—', style: muted),
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Gizlilik politikası',
          onTap: () => _openPrivacyPolicy(context),
        ),
        SettingsTile(
          icon: Icons.description_outlined,
          title: 'Açık kaynak lisansları',
          onTap: () => _openLicenses(context, version),
        ),
        SettingsTile(
          icon: Icons.mail_outline,
          title: 'Geri bildirim gönder',
          subtitle: AppAboutInfo.contactEmail,
          trailing: Icon(
            Icons.copy_outlined,
            size: AppIconSize.sm,
            color: palette.textMuted,
            semanticLabel: 'Kopyala',
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
      AppToast.success(context, 'E-posta adresi kopyalandı');
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
