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
import 'package:example_app/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_header.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.aboutSection = const AboutSection()});

  /// Injectable so tests and goldens can pin the build version.
  final Widget aboutSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloud = ref.watch(featureFlagsProvider).cloudSync;
    final user = cloud ? ref.watch(currentUserProvider) : null;
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
                  userName: cloud ? _userName(user) : null,
                  onNameTap: editName,
                ),
                gap,
                const _AppearanceSection(),
                gap,
                if (cloud) ...[
                  _AccountSection(user: user),
                  gap,
                ],
                const SettingsSection(
                  title: 'GİZLİLİK',
                  children: [CrashReportingSetting()],
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

  static String _userName(User? user) {
    final metadataName = user?.userMetadata?['name'];
    if (metadataName is String) return metadataName;
    final email = user?.email;
    if (email != null) return email.split('@').first;
    return 'Kullanıcı';
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppButton(
        label: 'Çıkış Yap',
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
    return SettingsSection(
      title: 'GÖRÜNÜM',
      children: [
        SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Tema',
          subtitle: SettingsDialogs.getThemeText(settings.themeMode),
          onTap: () => SettingsDialogs.showThemeDialog(context, ref, settings),
        ),
        const CanvasThemeSetting(),
        SettingsTile(
          icon: Icons.star_outline,
          title: 'Favorileri üste sabitle',
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
    return SettingsSection(
      title: 'HESAP',
      children: [
        SettingsTile(
          icon: Icons.lock_outline,
          title: 'Şifre değiştir',
          onTap: () => SettingsDialogs.showChangePasswordDialog(context),
        ),
        SettingsTile(
          icon: Icons.person_outline,
          title: 'Hesap bilgileri',
          onTap: () => SettingsDialogs.showAccountInfo(context, user),
        ),
      ],
    );
  }
}
