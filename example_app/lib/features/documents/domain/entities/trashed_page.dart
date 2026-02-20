import 'package:equatable/equatable.dart';

/// Represents a page that was soft-deleted (moved to trash).
/// Stored separately from the document to keep documents clean.
class TrashedPage extends Equatable {
  final String id;
  final String pageId;
  final String sourceDocumentId;
  final String sourceDocumentTitle;
  final int originalPageIndex;
  final DateTime deletedAt;
  final Map<String, dynamic> pageData;

  const TrashedPage({
    required this.id,
    required this.pageId,
    required this.sourceDocumentId,
    required this.sourceDocumentTitle,
    required this.originalPageIndex,
    required this.deletedAt,
    required this.pageData,
  });

  @override
  List<Object?> get props => [
        id,
        pageId,
        sourceDocumentId,
        sourceDocumentTitle,
        originalPageIndex,
        deletedAt,
      ];
}
