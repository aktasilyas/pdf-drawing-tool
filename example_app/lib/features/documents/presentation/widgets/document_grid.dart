import 'package:flutter/material.dart';
import '../../domain/entities/document_info.dart';
import 'document_card.dart';
import 'empty_state.dart';

class DocumentGrid extends StatelessWidget {
  final List<DocumentInfo> documents;
  final String emptyTitle;
  final String emptyDescription;
  final VoidCallback? onDocumentTap;
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        
        return DocumentCard(
          document: document,
          onTap: onDocumentTap,
          onLongPress: () => onDocumentLongPress?.call(document),
          onFavoriteToggle: () => onFavoriteToggle?.call(document),
          onMorePressed: () => onMorePressed?.call(document),
        );
      },
    );
  }
}
