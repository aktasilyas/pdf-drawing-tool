import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/l10n/l10n.dart';

/// Shows rename dialog for a document.
Future<void> showRenameDocumentDialog(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) async {
  final actions = ref.read(documentMenuActionsProvider);
  final title = await showDialog<String>(
    context: context,
    builder: (ctx) => RenameDialog(
      initialTitle: document.title,
      labelText: ctx.l10n.libraryDocumentNameLabel,
    ),
  );
  if (title != null) await actions.rename(document, title);
}
