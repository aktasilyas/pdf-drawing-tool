/// ElyaNotes Design System - AppToast Component
///
/// Toast/SnackBar komponenti.
///
/// Kullanım:
/// ```dart
/// AppToast.success(context, 'Kaydedildi!');
/// AppToast.error(context, 'Hata oluştu!');
/// AppToast.show(
///   context: context,
///   message: 'Mesaj',
///   type: AppToastType.warning,
///   actionLabel: 'Geri Al',
///   onAction: undo,
/// );
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Toast tipleri.
enum AppToastType {
  /// Başarı mesajı - Yeşil
  success,

  /// Hata mesajı - Kırmızı
  error,

  /// Uyarı mesajı - Sarı
  warning,

  /// Bilgi mesajı - Mavi
  info,
}

/// ElyaNotes toast/snackbar komponenti.
///
/// 4 farklı tip destekler, action button eklenebilir.
class AppToast {
  /// Toast göster.
  static void show({
    required BuildContext context,
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final config = _getConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              config.icon,
              color: config.iconColor,
              size: AppIconSize.md,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: config.textColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: config.actionColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Başarı toast'ı göster.
  static void success(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: AppToastType.success,
    );
  }

  /// Hata toast'ı göster.
  static void error(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: AppToastType.error,
    );
  }

  /// Uyarı toast'ı göster.
  static void warning(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: AppToastType.warning,
    );
  }

  /// Bilgi toast'ı göster.
  static void info(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: AppToastType.info,
    );
  }

  static _ToastConfig _getConfig(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return const _ToastConfig(
          icon: Icons.check_circle_outline,
          backgroundColor: AppColors.success,
          iconColor: Colors.white,
          textColor: Colors.white,
          actionColor: Colors.white,
        );
      case AppToastType.error:
        return const _ToastConfig(
          icon: Icons.error_outline,
          backgroundColor: AppColors.error,
          iconColor: Colors.white,
          textColor: Colors.white,
          actionColor: Colors.white,
        );
      case AppToastType.warning:
        return const _ToastConfig(
          icon: Icons.warning_amber_outlined,
          backgroundColor: AppColors.warning,
          iconColor: AppColors.textPrimaryLight,
          textColor: AppColors.textPrimaryLight,
          actionColor: AppColors.textPrimaryLight,
        );
      case AppToastType.info:
        return const _ToastConfig(
          icon: Icons.info_outline,
          backgroundColor: AppColors.info,
          iconColor: Colors.white,
          textColor: Colors.white,
          actionColor: Colors.white,
        );
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color actionColor;

  const _ToastConfig({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.actionColor,
  });
}
