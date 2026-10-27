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
import 'package:example_app/l10n/l10n.dart';

/// Helper class containing all settings screen dialogs.
abstract class SettingsDialogs {
  static String getThemeText(AppLocalizations l10n, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return l10n.settingsThemeLight;
      case AppThemeMode.dark:
        return l10n.settingsThemeDark;
      case AppThemeMode.system:
        return l10n.settingsThemeSystem;
    }
  }

  static void showThemeDialog(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final surfaceColor = context.palette.surface;
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textMuted;
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text(l10n.settingsThemeDialogTitle,
            style: AppTypography.titleLarge.copyWith(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            final isSelected = settings.themeMode == mode;
            return ListTile(
              title: Text(getThemeText(l10n, mode),
                  style: TextStyle(color: textPrimary)),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? context.palette.accent : textSecondary,
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
    final surfaceColor = context.palette.surface;
    final textPrimary = context.palette.textPrimary;
    final l10n = context.l10n;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text(l10n.settingsEditName,
            style: AppTypography.titleLarge.copyWith(color: textPrimary)),
        content: AppTextField(
          label: l10n.settingsNameLabel,
          controller: controller,
        ),
        actions: [
          AppButton(
              label: l10n.commonCancel,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx)),
          AppButton(
              label: l10n.commonSave,
              onPressed: () {
                // TODO: Supabase user metadata güncelle
                Navigator.pop(ctx);
              }),
        ],
      ),
    );
  }

  static void showChangePasswordDialog(BuildContext context) {
    AppToast.info(context, context.l10n.settingsChangePasswordSoon);
  }

  static void showAccountInfo(BuildContext context, User? user) {
    final surfaceColor = context.palette.surface;
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textMuted;
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.modal)),
        title: Text(l10n.settingsAccountInfoTitle,
            style: AppTypography.titleLarge.copyWith(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsAccountEmail(user?.email ?? '-'),
                style: AppTypography.bodyMedium.copyWith(color: textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.settingsAccountId(user?.id ?? '-'),
                style: AppTypography.caption.copyWith(color: textSecondary)),
          ],
        ),
        actions: [
          AppButton(
              label: l10n.commonClose,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  static Future<void> handleLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final result = await AppConfirmDialog.show(
      context: context,
      title: l10n.settingsLogout,
      message: l10n.settingsLogoutConfirm,
      confirmLabel: l10n.settingsLogout,
      cancelLabel: l10n.commonCancel,
      isDestructive: true,
    );
    if (result == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}
