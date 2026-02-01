/// StarNote Design System - AppModal Component
///
/// Responsive modal komponenti.
/// Phone: Bottom sheet, Tablet: Center dialog.
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

/// StarNote responsive modal komponenti.
///
/// Phone'da bottom sheet, tablet'te center dialog olarak gösterilir.
class AppModal {
  /// Modal göster.
  ///
  /// Breakpoint: 600px
  /// - < 600px: Bottom sheet (drag handle, rounded top)
  /// - >= 600px: Center dialog (max-width 560px, rounded all)
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
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
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
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceLight,
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
    return SafeArea(
      child: Padding(
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
                  color: AppColors.outlineVariantLight,
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
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (showCloseButton)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: AppIconSize.lg,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Content
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
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
              if (showCloseButton)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    size: AppIconSize.lg,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Content
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
