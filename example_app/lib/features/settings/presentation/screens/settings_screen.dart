/// ElyaNotes Settings screen.
///
/// With every feature flag off (v1.0) it shows: Görünüm (app theme, canvas
/// theme, pin favourites), Gizlilik (crash reports) and Hakkında (version,
/// privacy policy, licences, feedback). Account entries and logout appear
/// only when cloud sync is on.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/config/feature_flags.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/settings/domain/entities/app_settings.dart';
import 'package:example_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:example_app/features/settings/presentation/widgets/about_section.dart';
import 'package:example_app/features/settings/presentation/widgets/canvas_theme_setting.dart';
import 'package:example_app/features/settings/presentation/widgets/crash_reporting_setting.dart';
import 'package:example_app/features/settings/presentation/widgets/draw_with_finger_setting.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_header.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:example_app/l10n/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.aboutSection = const AboutSection()});

  /// Injectable so tests and goldens can pin the build version.
  final Widget aboutSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloud = ref.watch(featureFlagsProvider).cloudSync;
    final user = cloud ? ref.watch(currentUserProvider) : null;
    final l10n = context.l10n;
    final isTablet = Responsive.isTablet(context);
    const gap = SizedBox(height: AppSpacing.sectionSpacing);
    void editName() => SettingsDialogs.showEditNameDialog(context, ref);

    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              children: [
                SettingsHeader(
                  userName: cloud
                      ? _userName(user, l10n.settingsUserFallbackName)
                      : null,
                  onNameTap: editName,
                ),
                gap,
                const _AppearanceSection(),
                gap,
                if (cloud) ...[
                  _AccountSection(user: user),
                  gap,
                ],
                SettingsSection(
                  title: l10n.settingsSectionPrivacy,
                  children: const [CrashReportingSetting()],
                ),
                gap,
                aboutSection,
                const SizedBox(height: AppSpacing.xxl),
                if (cloud) ...[
                  const _LogoutButton(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _userName(User? user, String fallback) {
    final metadataName = user?.userMetadata?['name'];
    if (metadataName is String) return metadataName;
    final email = user?.email;
    if (email != null) return email.split('@').first;
    return fallback;
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppButton(
        label: context.l10n.settingsLogout,
        variant: AppButtonVariant.destructive,
        isExpanded: true,
        onPressed: () => SettingsDialogs.handleLogout(context, ref),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final pinFavorites = ref.watch(pinFavoritesProvider);
    final l10n = context.l10n;
    return SettingsSection(
      title: l10n.settingsSectionAppearance,
      children: [
        SettingsTile(
          icon: Icons.palette_outlined,
          title: l10n.settingsTheme,
          subtitle: SettingsDialogs.getThemeText(l10n, settings.themeMode),
          onTap: () => SettingsDialogs.showThemeDialog(context, ref, settings),
        ),
        const CanvasThemeSetting(),
        const DrawWithFingerSetting(),
        SettingsTile(
          icon: Icons.star_outline,
          title: l10n.settingsPinFavorites,
          showArrow: false,
          onTap: () => ref.read(pinFavoritesProvider.notifier).toggle(),
          trailing: Switch(
            value: pinFavorites,
            activeTrackColor: context.palette.accent,
            onChanged: (v) => ref.read(pinFavoritesProvider.notifier).set(v),
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSection(
      title: l10n.settingsSectionAccount,
      children: [
        SettingsTile(
          icon: Icons.lock_outline,
          title: l10n.settingsChangePassword,
          onTap: () => SettingsDialogs.showChangePasswordDialog(context),
        ),
        SettingsTile(
          icon: Icons.person_outline,
          title: l10n.settingsAccountInfo,
          onTap: () => SettingsDialogs.showAccountInfo(context, user),
        ),
      ],
    );
  }
}
