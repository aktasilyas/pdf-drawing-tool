import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/l10n/l10n.dart';

/// Shows rename dialog for a document.
void showRenameDocumentDialog(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
  final controller = TextEditingController(text: document.title);
  final actions = ref.read(documentMenuActionsProvider);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.commonRename),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: ctx.l10n.libraryDocumentNameLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            // Blank names are rejected by the action.
            actions.rename(document, controller.text);
            Navigator.pop(ctx);
          },
          child: Text(ctx.l10n.commonSave),
        ),
      ],
    ),
  );
}
