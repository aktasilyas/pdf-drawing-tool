/// ElyaNotes Design System - AppModal Component
///
/// Responsive, keyboard-safe modal komponenti.
/// Phone: Bottom sheet, Tablet: Center dialog.
///
/// Features:
/// - Keyboard açılınca yukarı kayar (viewInsets)
/// - isScrollControlled: true
/// - Dark theme uyumlu
///
/// Kullanım:
/// ```dart
/// AppModal.show(
///   context: context,
///   title: 'Başlık',
///   content: YourWidget(),
///   actions: [
///     AppButton(label: 'Kaydet', onPressed: save),
///   ],
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/index.dart';
import 'package:example_app/l10n/l10n.dart';

part 'app_modal_content.dart';

/// ElyaNotes responsive modal komponenti.
///
/// Phone'da bottom sheet, tablet'te center dialog olarak gösterilir.
/// Keyboard-safe: klavye açılınca modal yukarı kayar.
class AppModal {
  /// Modal göster.
  ///
  /// Breakpoint: 600px
  /// - < 600px: Bottom sheet (drag handle, rounded top, keyboard-safe)
  /// - >= 600px: Center dialog (max-width 560px, rounded all, scrollable)
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool isDismissible = true,
    bool showCloseButton = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    if (isPhone) {
      return _showBottomSheet<T>(
        context: context,
        title: title,
        content: content,
        actions: actions,
        isDismissible: isDismissible,
        showCloseButton: showCloseButton,
      );
    } else {
      return _showDialog<T>(
        context: context,
        title: title,
        content: content,
        actions: actions,
        isDismissible: isDismissible,
        showCloseButton: showCloseButton,
      );
    }
  }

  static Future<T?> _showBottomSheet<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    required bool isDismissible,
    required bool showCloseButton,
  }) {
    final surfaceColor = context.palette.surfaceElevated;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true, // ✅ Keyboard-safe
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (context) => _BottomSheetContent(
        title: title,
        content: content,
        actions: actions,
        showCloseButton: showCloseButton,
      ),
    );
  }

  static Future<T?> _showDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    required bool isDismissible,
    required bool showCloseButton,
  }) {
    final surfaceColor = context.palette.surfaceElevated;

    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _DialogContent(
            title: title,
            content: content,
            actions: actions,
            showCloseButton: showCloseButton,
          ),
        ),
      ),
    );
  }
}
