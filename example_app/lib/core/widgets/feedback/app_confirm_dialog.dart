/// ElyaNotes Design System - AppConfirmDialog Component
///
/// Onay dialogu komponenti.
///
/// Kullanım:
/// ```dart
/// final result = await AppConfirmDialog.show(
///   context: context,
///   title: 'Silmek istediğinize emin misiniz?',
///   message: 'Bu işlem geri alınamaz.',
///   isDestructive: true,
/// );
/// if (result == true) delete();
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/index.dart';

import 'app_modal.dart';

/// ElyaNotes onay dialogu komponenti.
///
/// İki butonlu (iptal/onayla) basit dialog.
class AppConfirmDialog {
  /// Onay dialogu göster.
  ///
  /// Returns: true (onaylandı), false (iptal), null (dismissed)
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Onayla',
    String cancelLabel = 'İptal',
    bool isDestructive = false,
  }) {
    return AppModal.show<bool>(
      context: context,
      title: title,
      content: _ConfirmDialogContent(message: message),
      actions: [
        AppButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
        ),
        AppButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          variant: isDestructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          size: AppButtonSize.medium,
        ),
      ],
      isDismissible: true,
      showCloseButton: false,
    );
  }
}

class _ConfirmDialogContent extends StatelessWidget {
  final String message;

  const _ConfirmDialogContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryLight,
      ),
    );
  }
}
