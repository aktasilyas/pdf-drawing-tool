import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/empty_state.dart';

class DocumentGrid extends StatelessWidget {
  final List<DocumentInfo> documents;
  final String emptyTitle;
  final String emptyDescription;
  final Function(DocumentInfo)? onDocumentTap;
  final Function(DocumentInfo)? onDocumentLongPress;
  final Function(DocumentInfo)? onFavoriteToggle;
  final Function(DocumentInfo)? onMorePressed;

  const DocumentGrid({
    super.key,
    required this.documents,
    required this.emptyTitle,
    required this.emptyDescription,
    this.onDocumentTap,
    this.onDocumentLongPress,
    this.onFavoriteToggle,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.description_outlined,
          title: emptyTitle,
          description: emptyDescription,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.7,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisSpacing: AppSpacing.lg,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        
        return DocumentCard(
          document: document,
          onTap: () => onDocumentTap?.call(document),
          onLongPress: () => onDocumentLongPress?.call(document),
          onFavoriteToggle: () => onFavoriteToggle?.call(document),
          onMorePressed: () => onMorePressed?.call(document),
        );
      },
    );
  }
}
