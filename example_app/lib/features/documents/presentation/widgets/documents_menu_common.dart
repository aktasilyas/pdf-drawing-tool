import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Shows a themed modal bottom sheet for library menus.
void showMenuSheet(
  BuildContext context,
  List<Widget> Function(BuildContext sheetContext) children,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          ...children(ctx),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

/// Soft divider matching settings/sidebar pattern (0.5px, outlineVariant).
Widget softDivider(BuildContext context) {
  return Divider(
    height: 0.5,
    thickness: 0.5,
    color: context.palette.border,
    indent: 56,
  );
}

/// Shows a floating snack bar with [message].
void showMenuSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Confirmation dialog for permanent delete actions.
Future<bool?> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final surfaceColor = context.palette.surface;
  final textPrimary = context.palette.textPrimary;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: surfaceColor,
      title: Text(title,
          style: AppTypography.titleLarge.copyWith(color: textPrimary)),
      content: Text(message,
          style: AppTypography.bodyMedium.copyWith(color: textPrimary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(ctx.l10n.libraryDeleteForever),
        ),
      ],
    ),
  );
}
