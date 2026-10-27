import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/widgets/document_list_tile.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_list_tile.dart';
import 'package:example_app/features/documents/presentation/widgets/library_grid_metrics.dart';
import 'package:example_app/features/documents/presentation/widgets/library_list_row.dart';
import 'package:example_app/l10n/l10n.dart';

/// Combined list view showing folders then documents.
class DocumentsCombinedListView extends ConsumerWidget {
  const DocumentsCombinedListView({
    super.key,
    required this.folders,
    required this.documents,
    required this.onFolderTap,
    required this.onDocumentTap,
    required this.onFolderMore,
    required this.onDocumentMore,
  });

  final List<Folder> folders;
  final List<DocumentInfo> documents;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pad = LibraryGridMetrics.paneHorizontalPadding(
      Responsive.isPhone(context),
    );

    final children = <Widget>[
      if (folders.isNotEmpty) ...[
        _SectionHeader(label: l10n.libraryFolders, isFirst: true),
        for (var i = 0; i < folders.length; i++)
          _Row(
            showDivider: i < folders.length - 1,
            child: FolderListTile(
              folder: folders[i],
              onTap: () => onFolderTap(folders[i]),
              onLongPress: () => onFolderMore(folders[i]),
            ),
          ),
      ],
      if (documents.isNotEmpty) ...[
        _SectionHeader(
          label: l10n.libraryDocuments,
          isFirst: folders.isEmpty,
        ),
        for (var i = 0; i < documents.length; i++)
          _Row(
            showDivider: i < documents.length - 1,
            child: DocumentListTile(
              document: documents[i],
              onTap: () => onDocumentTap(documents[i]),
              onLongPress: () => onDocumentMore(documents[i]),
            ),
          ),
      ],
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, AppSpacing.sm, pad, AppSpacing.xxl),
      children: children,
    );
  }
}

/// A row followed by an optional hairline starting at the text column.
class _Row extends StatelessWidget {
  const _Row({required this.child, required this.showDivider});

  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        child,
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: LibraryListRow.dividerIndent,
            color: context.palette.border,
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.isFirst = false});

  final String label;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        top: isFirst ? 0 : AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium
            .copyWith(color: context.palette.textMuted),
      ),
    );
  }
}
