/// StarNote Settings Screen - Design system settings page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:example_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:example_app/features/settings/presentation/widgets/profile_header.dart';
import 'package:example_app/features/settings/domain/entities/app_settings.dart';
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

    // Theme-aware colors
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: AppIconButton(
          icon: Icons.arrow_back,
          variant: AppIconButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
        title: Text('Ayarlar',
            style: AppTypography.titleLarge.copyWith(color: textPrimary)),
        centerTitle: !isTablet,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            children: [
              // Profil Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ProfileHeader(
                  name: user?.userMetadata?['name'] as String? ??
                      user?.email?.split('@').first ??
                      'Kullanıcı',
                  email: user?.email ?? '',
                  isPremium: false,
                  onTap: () => _showEditNameDialog(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Görünüm
              SettingsSection(
                title: 'GÖRÜNÜM',
                children: [
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Tema',
                    subtitle: _getThemeText(settings.themeMode),
                    onTap: () => _showThemeDialog(context, ref, settings),
                  ),
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
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Hesap
              SettingsSection(
                title: 'HESAP',
                children: [
                  SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Şifre değiştir',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Hesap bilgileri',
                    onTap: () => _showAccountInfo(context, user),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Veri
              SettingsSection(
                title: 'VERİ',
                children: [
                  SettingsTile(
                    icon: Icons.upload_outlined,
                    title: 'Dışa aktar',
                    onTap: () => _showExportDialog(context),
                  ),
                  SettingsTile(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Önbelleği temizle',
                    onTap: () => _clearCache(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Hakkında
              SettingsSection(
                title: 'HAKKINDA',
                children: [
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
                    onTap: () => _openLegalPage(context, 'privacy'),
                  ),
                  SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Kullanım koşulları',
                    onTap: () => _openLegalPage(context, 'terms'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Çıkış Yap
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppButton(
                  label: 'Çıkış Yap',
                  variant: AppButtonVariant.destructive,
                  isExpanded: true,
                  onPressed: () => _handleLogout(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeText(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Açık';
      case AppThemeMode.dark:
        return 'Koyu';
      case AppThemeMode.system:
        return 'Sistem';
    }
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text('Tema Seçin',
            style: AppTypography.titleLarge.copyWith(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            final isSelected = settings.themeMode == mode;
            return ListTile(
              title: Text(_getThemeText(mode),
                  style: TextStyle(color: textPrimary)),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : textSecondary,
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).setTheme(mode);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text('İsim Düzenle',
            style: AppTypography.titleLarge.copyWith(color: textPrimary)),
        content: AppTextField(label: 'Adınız', controller: controller),
        actions: [
          AppButton(
              label: 'İptal',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx)),
          AppButton(
              label: 'Kaydet',
              onPressed: () {
                // TODO: Supabase user metadata güncelle
                Navigator.pop(ctx);
              }),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    AppToast.info(context, 'Şifre değiştirme özelliği yakında');
  }

  void _showAccountInfo(BuildContext context, User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text('Hesap Bilgileri',
            style: AppTypography.titleLarge.copyWith(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? "-"}',
                style: AppTypography.bodyMedium.copyWith(color: textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text('ID: ${user?.id ?? "-"}',
                style: AppTypography.caption.copyWith(color: textSecondary)),
          ],
        ),
        actions: [
          AppButton(
              label: 'Kapat',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    AppToast.info(context, 'Dışa aktarma özelliği yakında');
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final result = await AppConfirmDialog.show(
      context: context,
      title: 'Önbelleği Temizle',
      message: 'Uygulama önbelleği temizlenecek. Devam etmek istiyor musunuz?',
      confirmLabel: 'Temizle',
    );
    if (result == true && context.mounted) {
      // TODO: Cache temizleme
      AppToast.success(context, 'Önbellek temizlendi');
    }
  }

  void _openLegalPage(BuildContext context, String type) {
    AppToast.info(context, '$type sayfası yakında eklenecek');
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final result = await AppConfirmDialog.show(
      context: context,
      title: 'Çıkış Yap',
      message: 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
      confirmLabel: 'Çıkış Yap',
      isDestructive: true,
    );
    if (result == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}
