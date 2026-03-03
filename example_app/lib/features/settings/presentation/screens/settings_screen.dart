/// ElyaNotes Settings Screen - Multinet style design
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:example_app/features/settings/presentation/widgets/canvas_theme_setting.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_dialogs.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final pinFavorites = ref.watch(pinFavoritesProvider);
    final isTablet = Responsive.isTablet(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.surfaceContainerLowDark
        : AppColors.surfaceContainerLowLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final userName = user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        'Kullanıcı';
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              children: [
                _buildHeader(
                    context, initials, userName, textPrimary, isDark, ref),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _buildAppearanceSection(context, ref, settings, pinFavorites),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _buildAccountSection(context, ref, user),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _buildDataSection(context, ref),
                const SizedBox(height: AppSpacing.sectionSpacing),
                _buildAboutSection(context, isDark),
                const SizedBox(height: AppSpacing.xxl),
                _buildLogoutButton(context, ref),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String initials, String userName,
      Color textPrimary, bool isDark, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppAvatar(
                initials: initials,
                size: AppAvatarSize.medium,
                backgroundColor: AppColors.primary,
              ),
              AppIconButton(
                icon: Icons.close,
                variant: AppIconButtonVariant.ghost,
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => SettingsDialogs.showEditNameDialog(context, ref),
            child: Text(
              userName,
              style: AppTypography.headlineMedium.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref,
      dynamic settings, bool pinFavorites) {
    return SettingsSection(
      title: 'GÖRÜNÜM',
      children: [
        SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Tema',
          subtitle: SettingsDialogs.getThemeText(settings.themeMode),
          onTap: () =>
              SettingsDialogs.showThemeDialog(context, ref, settings),
        ),
        const CanvasThemeSetting(),
        SettingsTile(
          icon: Icons.star_outline,
          title: 'Favorileri üste sabitle',
          showArrow: false,
          trailing: Switch(
            value: pinFavorites,
            activeTrackColor: AppColors.primary,
            onChanged: (v) =>
                ref.read(pinFavoritesProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(
      BuildContext context, WidgetRef ref, User? user) {
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

  Widget _buildDataSection(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'VERİ',
      children: [
        SettingsTile(
          icon: Icons.upload_outlined,
          title: 'Dışa aktar',
          onTap: () => SettingsDialogs.showExportDialog(context),
        ),
        SettingsTile(
          icon: Icons.cleaning_services_outlined,
          title: 'Önbelleği temizle',
          onTap: () => SettingsDialogs.clearCache(context, ref),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return SettingsSection(
      title: 'HAKKINDA',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
          child: Center(
            child: Image.asset(
              'assets/images/elyanotes_logo.png',
              width: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.info_outline,
          title: 'Versiyon',
          showArrow: false,
          trailing: Text('1.0.0 (1)',
              style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Gizlilik politikası',
          onTap: () => SettingsDialogs.openLegalPage(context, 'privacy'),
        ),
        SettingsTile(
          icon: Icons.description_outlined,
          title: 'Kullanım koşulları',
          onTap: () => SettingsDialogs.openLegalPage(context, 'terms'),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
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
