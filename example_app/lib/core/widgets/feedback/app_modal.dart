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

// ══════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET CONTENT
// ══════════════════════════════════════════════════════════════════════════

class _BottomSheetContent extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const _BottomSheetContent({
    required this.title,
    required this.content,
    required this.actions,
    required this.showCloseButton,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textPrimary = palette.textPrimary;
    final handleColor = palette.border;

    return SafeArea(
      child: Padding(
        // ✅ Keyboard-safe: klavye açılınca modal yukarı kayar
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xs,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (showCloseButton) const _ModalCloseButton(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Content (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: content,
              ),
            ),
            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(actions!),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(List<Widget> actions) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) children.add(const SizedBox(width: AppSpacing.sm));
      children.add(actions[i]);
    }
    return children;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// DIALOG CONTENT
// ══════════════════════════════════════════════════════════════════════════

class _DialogContent extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const _DialogContent({
    required this.title,
    required this.content,
    required this.actions,
    required this.showCloseButton,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textPrimary = palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: textPrimary,
                  ),
                ),
              ),
              if (showCloseButton) const _ModalCloseButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Content (scrollable - keyboard-safe)
          Flexible(
            child: SingleChildScrollView(
              child: content,
            ),
          ),
          // Actions
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(actions!),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(List<Widget> actions) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) children.add(const SizedBox(width: AppSpacing.sm));
      children.add(actions[i]);
    }
    return children;
  }
}

/// Close button shared by the sheet and the dialog layout. `AppIconButton`
/// carries the 48dp hit area and the screen-reader label.
class _ModalCloseButton extends StatelessWidget {
  const _ModalCloseButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.close,
      variant: AppIconButtonVariant.ghost,
      tooltip: context.l10n.commonClose,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
