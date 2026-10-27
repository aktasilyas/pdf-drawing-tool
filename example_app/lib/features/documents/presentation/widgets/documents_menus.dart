import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/widgets/document_normal_menu.dart';
import 'package:example_app/features/documents/presentation/widgets/document_trash_menu.dart';

export 'package:example_app/features/documents/presentation/widgets/rename_document_dialog.dart';
export 'package:example_app/features/documents/presentation/widgets/trashed_page_menu.dart';

/// Shows the appropriate document menu based on whether it's in trash.
void showDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document, {
  required bool isTrash,
}) {
  if (isTrash) {
    showTrashDocumentMenu(context, ref, document);
  } else {
    showNormalDocumentMenu(context, ref, document);
  }
}
