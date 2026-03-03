/// ElyaNotes Settings Dialogs - Extracted dialog methods
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:example_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:example_app/features/settings/domain/entities/app_settings.dart';

/// Helper class containing all settings screen dialogs.
abstract class SettingsDialogs {
  static String getThemeText(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Açık';
      case AppThemeMode.dark:
        return 'Koyu';
      case AppThemeMode.system:
        return 'Sistem';
    }
  }

  static void showThemeDialog(
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
              title: Text(getThemeText(mode),
                  style: TextStyle(color: textPrimary)),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : textSecondary,
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

  static void showEditNameDialog(BuildContext context, WidgetRef ref) {
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

  static void showChangePasswordDialog(BuildContext context) {
    AppToast.info(context, 'Şifre değiştirme özelliği yakında');
  }

  static void showAccountInfo(BuildContext context, User? user) {
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

  static void showExportDialog(BuildContext context) {
    AppToast.info(context, 'Dışa aktarma özelliği yakında');
  }

  static Future<void> clearCache(BuildContext context, WidgetRef ref) async {
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

  static void openLegalPage(BuildContext context, String type) {
    AppToast.info(context, '$type sayfası yakında eklenecek');
  }

  static Future<void> handleLogout(
      BuildContext context, WidgetRef ref) async {
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
