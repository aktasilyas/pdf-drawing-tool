import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';

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
      title: const Text('Yeniden Adlandır'),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Belge Adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            // Blank names are rejected by the action.
            actions.rename(document, controller.text);
            Navigator.pop(ctx);
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}
